#!/usr/bin/perl
# $RCSfile$
# $Revision$ $Date$
# Auth: David Loffredo (loffredo@steptools.com)
#
# Fix Frame HTML - Post-process to collapse code and function
# prototypes into an indented PRE block, add headers and footers, and
# strip <A> identifiers for paragraph styles that will never appear in
# a cross reference.
# 
# Need the Image-Info package
#
#
use strict;
use File::Path;
use File::Copy;
## use Image::Info qw(image_info dim);   # for getting image sizes

my %book = 
    (name    => "unknown", 
     title   => "Unknown STEP Tools Book", 
     product => "ST-UNKNOWN",
     year    => &get_current_year,
     csslink => "../style.css",
     crlink  => "../copyright.html" );

my $srcdir  = ".";
my $outdir  = "clean_html";

my @image_paths;
my %image_mapping;
my %image_extras;

our %html;


sub usage {
    print <<PERL_EOF;
Usage: $0 [options] <name> [<name2> ...]

Post-process FrameMaker HTML book.  Rewrites the tagging into a
reasonable approximation of our printed styles. Removes extraneous
tags and style sheet clutter.  Adds navigation links to all section,
prev/next chapter, etc.  Maps images, computes sizes and puts in ALT
tags for better viewing.

 -help			Print out this usage message.
 -index			Add links to an index for the book.
 -I<dir>		Add <dir> to image search path.
 -src <dir>		Look for source in <dir> 
 -o <dir>		Put completed files in <dir>

 -map <file>		Use image map file.
 -copyright <file>	Link to copyright <file>.
 -style <file>		Link to stylesheet <file>.
 -product <str>		Use <str> as the STEP Tools product name.
 -title <str>		Use <str> as the title of the book.
PERL_EOF
    ;
    exit(0);
}

sub get_current_year
{
    my $yr = ((localtime)[5]+1900);
    my $mo = ((localtime)[4]);

    if ($mo > 7) {
	$yr++;
	print "NOTE: In last quarter of year, so using $yr as year.\n";
    }
    return $yr;
}

sub expand {
    my $body = shift;
    while ($_[0]) {
	my $sub = shift;
	my $repl = shift;
	$body =~ s/%%$sub%%/$repl/g;
    }
    return $body;
}

sub divwrap {
    my($class, @lines) = @_;
    return ("<div class=$class>\n", @lines, "</div>\n");
}



sub load_image_mapping {
    my($src) = @_;
    my ($loc, $old_image, $new_image, $extra_html);
    local($_);
    local(*SRC);

    print "$src: importing image mappings\n";

    open (SRC, "$src") || do {
	print "WARNING: No image map $src\n";
	return;
    };

    while (<SRC>) {
	next if /^#/;

	chomp; 
	($loc, $old_image, $new_image, $extra_html) = split(' ', $_, 4);

	next if $old_image eq "";
	$image_mapping{$old_image} = $new_image;
	$image_extras{$old_image}  = $extra_html;
    }

    close (SRC);
}

# Reads the HTMLfile into memory, strips useless html, and saves only
# the contents of the body. 

sub scan_htmlfile {
    my($file, $srcpath) = @_;
    my (@dst);
    local ($_, *SRC);

    open (SRC, $srcpath) or die "could not read $srcpath";
    while (<SRC>) {
	# Save the title for later use.  Strip the whitespace so that
	# it is a little nicer looking that what comes out of Frame.
	/<TITLE>(.*)<\/TITLE>/ && do {
	    my $t = $1;  # strip whitespace
	    $t =~ s/^\s+//;
	    $t =~ s/\s+$//;
	    $t =~ s/\s+/ /;
	    $book{$file}->{title} = $t;
	};

	# Dump the everything before the header, which has been
	# previously pushed to dst.  
	#
	/<BODY[^>]+>/ and do {
	    @dst = undef;  next;
	};

	# Ignore everything after the body.
	/<\/BODY>/ and last;

	# strip useless DIVs, but be careful because they are not
	# always on separate lines
	/^<\/?DIV>$/ && next;
	s/<\/?DIV>//g;

	# strip out spurious <MAP></MAP> definitions
	/^<MAP NAME/ && do {
	    $_ = <SRC>;
	    next;
	};

	# strip out the FrameMaker paragraph ids
	s/<A NAME=\"pgfId-[^\"]*\"><\/A>//g;

	# strip silly table spans
	s/ ROWSPAN="1" COLSPAN="1"//;

	# Give any normal tables a special class and force center
	# alignment.  IE will not center tables through CSS unless
	# you center the entire body block.
	/<TABLE([^>]*)>/ and do {
	    my $atts = $1;
	    $atts =~ s/CLASS=\"[^\"]*\"//;
	    $atts .= " class=normal align=\"center\"";
	    s/<TABLE[^>]*>/<TABLE $atts>/;
	};

	# # They screw up figure cross references. Strip them out
	# /<A HREF=\"[\w\.]+#[^\"]+\" CLASS=\"XRef\">$/ && do {	
	#     s/<A HREF=\"[\w\.]+#[^\"]+\" CLASS=\"XRef\">$//; chop;
	#     $_ .= <SRC>;
	#     s/<\/A>$//;
	# };

	# This can be handled with the style sheets
	# default headers are a little goofy
	s/<H6/<H4/;
	s/<\/H6/<\/H4/;

	s/<H5/<H4/;
	s/<\/H5/<\/H4/;

	/<(H\d)[^>]*CLASS=\"((chapter|section-one|section-two))\">/ && do {
	    my($tag) = $1;
	    my($style) = $2;
	    my($buf) = $_;

	    # pull the entire begin/end into one string
	    until (/<\/$tag>/) {
		$_ = <SRC>;
		$buf .= $_;
	    }

	    # scrap any newlines and FrameMaker paragraph ids
	    $buf =~ tr/\n/ /;
	    $buf =~ s/<A NAME=\"pgfId-[^\"]*\"><\/A>//g;
	    $buf =~ s/(<$tag[^>]*>)(.+)(<A NAME=[^>]+><\/A>)/$1$3$2/g;
	    $buf =~ s/<\/?DIV>//g;
	    $buf =~ s/\s+/ /g;
	    $buf =~ s/^\s//;
	    $buf =~ s/\s$//;

	    if ($style eq "chapter" && !$book{$file}->{chapter}) {
		$buf =~ s/<$tag[^>]*>/<$tag><A NAME=\"SEC0-0-0\"><\/A>$book{title}<BR>/;
		$buf =~ s/(<$tag>)(.+)(<A NAME=[^>]+><\/A>)/$1$3$2/g;
		$book{$file}->{chapter} = $buf;
		next;
	    }
	    $_ = $buf . "\n";
	};
	
	# cross ref page and section are useless in HTML
	s/\s*\(Section [0-9\.]*, pp\. \d*\)\s*//;
	s/\s*\(Chapter [0-9]*, pp\. \d*\)\s*//;

	push @dst, $_;
    }

    close (SRC);

    # Ditch any whitespace at the start.
    while ($dst[0] =~ /^\s*$/) { shift @dst; }
    return @dst;
}

sub correct_header_entries {
    my($file, @src) = @_;
    my (@dst);
    my $chap=0;
    my $sectone=0;
    my $secttwo=0;
    local ($_);

    # strip out silly images, but leave any extras behind and move out
    # of the header.   Replace the start of the page with a proper title
    # and logo block

    while (@src) {
	$_ = shift @src;

	# We have previously collapsed all head tags to one line 
	/<(H\d)[^>]*CLASS=\"((chapter|section-one|section-two))\">/ && do {
	    my($tag) = $1;
	    my($style) = $2;
	    my($buf) = $_;
	    my($anchors);

	    # pull out text before and after the tags.
	    $buf =~ /(.*)(<$tag.*?\/$tag>)(.*)/;
	    $buf = $2;
	    my $text_before = $1;
	    my $text_after = $3;

	    # The custom rules for the section tags come out as
	    # references to nonexistant gif files.  Replace with a
	    # ruled class for all but the first one.
	    my @images = $buf =~ /<IMG SRC[^>]*>/g;
	    $buf =~ s/<IMG SRC[^>]*>//g;

	    if ($style =~ /section-(one|two)/) {
		shift (@images) ;
	    }

	    # pull out any anchors and put them at the beginning. This
	    # is nice because it cleans up any split header text
	    $anchors = join ("", $buf =~ /(<A[^>]*>).*?(<\/A>)/g);
	    $buf =~ s/<A[^>]*>(.*?)<\/A>/$1/g;
	    $buf =~ s/(<$tag[^>]*>)/$1$anchors/;

	    # scrap excess whitespace before and after tags;
	    $buf =~ s/\s+</</g;
	    $buf =~ s/>\s+/>/g;

	    # add markers for future toc generation. 
	    # add horizontal rules for section one and two
	    # We strip the first chapter when we read the file, so there
	    # should not be anymore
	    ($style eq "chapter") && do {
		# Also add the book title to the section headers
		$chap++; $sectone=0; $secttwo=0;
		$buf =~ s/(<$tag[^>]*>)/$1$book{title}<BR><A NAME=\"SEC$chap-$sectone-$secttwo\"><\/A>/;
		#$buf =~ s/(<$tag[^>]*>)/<$tag>$book{title}<BR><A NAME=\"SEC$chap-$sectone-$secttwo\"><\/A>/;
	    };

	    # Skip the rule for the first one, it looks bad w/chapter head 
	    # Stick in a rule class for the others <H2 class=rule>

	    ($style eq "section-one") && do {
		$sectone++; $secttwo=0;
		$buf =~ s/(<$tag[^>]*>)/$1<A NAME=\"SEC$chap-$sectone-$secttwo\"><\/A>/;
		$buf =~ s/<($tag[^>]*)>/<$tag class=rule>/ if ($sectone > 1);
		#$buf =~ s/(<$tag[^>]*>)/$1$html{section_one_rule}/ if ($sectone > 1);
	    };

	    ($style eq "section-two") && do {
		$secttwo++;
		$buf =~ s/(<$tag[^>]*>)/$1<A NAME=\"SEC$chap-$sectone-$secttwo\"><\/A>/;
		$buf =~ s/<($tag[^>]*)>/<$tag class=rule>/;
		#$buf =~ s/(<$tag[^>]*>)/$1$html{section_two_rule}/;
	    };

	    # break it up into multiple lines.  Toss anchors on
	    # separate lines as well as the final closing tag.

	    $buf =~ s/(<A[^>]*>.*?<\/A>)/\n$1\n/g;
	    $buf =~ s/(<\/$tag>)/\n$1/ if $buf =~ /\n/;
	    $buf =~ s/\n\n+/\n/g;
	    
	    push @dst, ($text_before, "\n") if ($text_before ne "");
	    push @dst, ("\n", $buf, "\n");
	    push @dst, (join ("\n", @images), "\n") if scalar(@images);
	    push @dst, ($text_after, "\n")  if ($text_after ne "");
	    next;
	};

	push @dst, $_;
    }
    return @dst;
}



sub correct_image_entries {
    my($file, @src) = @_;
    my (@dst);
    local ($_);

    # strip out silly images, but leave any extras behind and move out
    # of the header

    while (@src) {
	$_ = shift @src;

	/<IMG SRC=\"([^\"]*)\"[^>]*>/ && do {
	    my $imgfile = $1;
	    my $buf = $_;
	    my $extra  = $image_extras{$imgfile};
	    my $tmpl = "<P ALIGN=CENTER>";

	    # handle image mapping options
	    if ($extra =~ /<center>/i) {
		$extra =~ s/<center>//i;
		# this is the default, perhaps we can us a special
		# figure style
	    }

	    if ($extra =~ /<inline>/i) {
		$extra =~ s/<inline>//i;
		$tmpl = "";
	    }

	    # handle the mapping destination 
	    ($image_mapping{$imgfile} eq "alert") && do {
		# Alerts are normally put after the paragraph they
		# deal with, so back up and add the alert to the class.
		my @tmp;
		$buf =~ s/<IMG SRC[^>]*>//;
		while (not ($buf=~ /<P[^>]*>/)) {
		    unshift @tmp, $buf;
		    $buf = pop @dst;
		}
		$buf=~ s/<P([^>]*)>/<P class=alert$1>/;
		push @dst, $buf, @tmp;

		# $buf =~ s/<IMG SRC[^>]*>/$html{alert}/;
		# push @dst, $buf;
		next;
	    };

	    ($image_mapping{$imgfile} eq "delete") && do {
		$buf =~ s/<IMG SRC[^>]*>//;
		push @dst, $buf;
		next;
	    };

	    ($image_mapping{$imgfile} eq "keep") && do {
		my($rawfile) = $imgfile;

		# make inline
		$tmpl = "";

		# remove any extra beginning path
		$rawfile =~ s/.*\///i;

		# replace existing image
		$tmpl .= &build_image_tag ($rawfile, $extra);
		$buf =~ s/<IMG SRC[^>]*>/\n$tmpl/;

		push @dst, $buf;
		next;
	    };

	    # we could probably make a keep tag that keeps the same
	    # filename, does the sizing, centering, but lets us
	    # annotate with an alt tag.  Make the no mapping behavior
	    # also rewrite with sizes etc, but do it inline for all of
	    # the little inline tags that alex uses.

	    ($image_mapping{$imgfile} ne "") && do {

		# replace existing image
		# <div class=figure><img src="images/vc10_libs.gif"></div>
		#$tmpl .= &build_image_tag ($image_mapping{$imgfile}, $extra);
		$tmpl = '<div class=figure>';
		$tmpl .= &build_image_tag ($image_mapping{$imgfile}, $extra);
		$tmpl .= "<p>$extra" if $extra ne "";
		$tmpl .= '</div>';
		$buf =~ s/<IMG SRC[^>]*>/\n$tmpl/;

		push @dst, $buf;
		next;
	    };

	    # not handled in the mapping
	    print (STDOUT "IMAGE: used unchanged $file -- $imgfile\n");
	};

	push @dst, $_;
    }

    return @dst;
}

#----------------------------------------
# finds the bug number and tags the file if it does not have one
#
sub correct_paragraph_styles {
    my($file, @src) = @_;
    my (@dst);
    local ($_);

  OUTER: while (@src) {
      $_ = shift @src;

    LOOP: {
	while (/([^<]*<[^>]*>)*<[^>]*$/) {
	    $_ .= shift @src;
	}
	
	/<([^>]*) CLASS=\"([^\"]*)\">/ && do {
	    my($tag) = $1;
	    my($style) = $2;

	    # Combine all contiguous code paragraphs into a single
	    # indented PRE block.  Make sure we convert hard tabs into
	    # a fixed number of spaces.  
	    #
	    ($style eq "code") && do {
		push @dst, "<PRE class=code>\n";
		while (/<(.*) CLASS=\"code\">/) {
		    $_ = shift @src;
		    push @dst, $html{indent};
		    while (! ($_ =~ /<\/$tag>/) ) {
			s/<(.*) CLASS=\"(.*)\">/<$1>/;
			s/\t/$html{indent}/;
			chop $_;  push @dst, $_; $_ = shift @src;

		    }
		    s/(.*)<\/$tag>/$1/;
		    s/\t/$html{indent}/;
		    push @dst, $_;
		    $_ = shift @src;
		}
		push @dst, "</PRE>\n";
		redo;
	    };

	    # Combine function prototypes into a single PRE block.
	    # Indent any func proto cont paragraphs, but keep them in
	    # the same pre block.  Be sure to strip useless whitespace
	    # from the beginning of funcproto lines, otherwise they
	    # may be oddly indented.
	    #
	    ($style eq "func-proto") && do {
		my($buf) = "";

		push @dst, "<PRE>\n";
		$_ = shift @src;
		while (! ($_ =~ /<\/$tag>/) ) {
		    s/<(.*) CLASS=\"(.*)\">/<$1>/;
		    chop $_; $buf .= $_; 
		    $_ = shift @src;
		}
		# strip any initial whitespace
		$buf =~ s/^\s+(.*)/$1/;

		s/(.*)<\/$tag>/$1/;
		push @dst, ($buf, $_);

		$_ = shift @src;
		while (/<(.*) CLASS=\"func-proto-cont\">/) {
		    $_ = shift @src;
		    push @dst, "\t";
		    while (! ($_ =~ /<\/$tag>/) ) {
			s/<(.*) CLASS=\"(.*)\">/<$1>/;
			chop $_;  push @dst, $_; $_ = shift @src;
		    }
		    s/(.*)<\/$tag>/$1/;
		    push @dst, $_;
		    $_ = shift @src;
		}

		push @dst, "</PRE>\n";
		redo;
	    };



	    # Combine param prototypes into a definition list.  Make
	    # sure that the cont paragraphs are tacked on
	    #
	    ($style eq "parm-proto" ||
	     $style eq "parm-proto-long") && do {
		 push @dst, "<DL>\n";
		 push @dst, "<DT><CODE>\n";
		 $_ = shift @src;

		 while (! ($_ =~ /<\/$tag>/) ) {
		     s/<(.*) CLASS=\"(.*)\">/<$1>/;
		     chop $_;  push @dst, $_; $_ = shift @src;
		 }
		 s/(.*)<\/$tag>/$1<\/CODE>/;
		 push @dst, $_;

		 $_ = shift @src;
		 while (/<(.*) CLASS=\"parm-proto-cont\">/) {
		     my($conttag)=$1;
		     $_ = shift @src;
		     push @dst, "<DD>";
		     while (! ($_ =~ /<\/$conttag>/) ) {
			 s/<(.*) CLASS=\"(.*)\">/<$1>/;
			 #chop $_;
			 push @dst, $_; $_ = shift @src;
		     }
		     s/(.*)<\/$conttag>/$1/;
		     push @dst, $_;
		     $_ = shift @src;
		     # separate subsequent param proto lines
		     push @dst, "<P>" if /<.* CLASS=\"parm-proto-cont\">/;
		 }

		 push @dst, "</DL>\n";
		 redo;
	     };

	    ($style eq "XRef") && do {
		
		/(.*?<.*? CLASS=\".*?\">)(.*)/;
		$_ = $1;
		my $rest=$2;
		s/<(.*?) CLASS=\"(.*?)\">(.*)/<$1>/; 

		chomp $_;  push @dst, $_;

		while ($rest || ! ($_ =~ /<\/A>/) ) {
		    if ($rest) {
			$_ = $rest;
			$rest = undef;
		    }
		    else {
			$_ = shift @src;
		    }

		    s/<(.*) CLASS=\".*\">/<$1>/;
		    s/<\/?STRONG>//;
		    
		    # Remove default section and page number things from cross
		    # references.  TEMPORARY until I can change the Xref style
		    # in the generator.
		    #
		    # Now in stripping of useless html
		    #s/\s*\(Section [0-9\.]*, pp\. \d*\)\s*//;
		    #s/\s*\(Chapter [0-9]*, pp\. \d*\)\s*//;

		    if (/(.*?<\/A>)(.*)/) {

			my $rest = $2;
			my $pfx = $1;

			if ($rest =~ /<A HREF=/) {
			    push @dst, $pfx;
			    $_ = $rest;
			    goto LOOP;
			} 
		    }

		    chomp $_;  push @dst, $_;
		}
		push @dst, "\n";
		next OUTER;
	    };


	    # strip class by default
	    s/<([^>]*) CLASS=\"[^\"]*\">/<$1>/;
	}
    };

      push @dst, $_;
  }
    return @dst;
}

sub build_chapter_toc {
    my($file, @src) = @_;
    local ($_);

    my @dst;
    my @toc;
    my $lastlevel=0;
    my $closestr ="";
    my @tmp = @src;

    while (@tmp) {
	$_ = shift @tmp;

	/<H([123])[^>]*>/ && do {
	    my $level = $1;
	    my($buf) = $_;
	    my($href);

	    # pull the entire begin/end into one string
	    until (/<\/H$level>/) { $_ = shift @tmp; $buf .= $_; }

	    # scrap any newlines
	    $buf =~ tr/\n/ /;

	    # find the section name that we gave it earlier or else
	    # continue because it is not ours.
	    $buf =~ /<A NAME=\"(SEC[^\"]*)\">/  || next; 
	    $href = $1;

	    # wipe out all remaining tags, beginning whitespace and
	    # trailing whitespace
	    $buf =~ s/<[^>]*>//g;
	    $buf =~ s/^\s+//;
	    $buf =~ s/\s+$//;

	    # close previous level?
	    while ( $level < $lastlevel ) {
		# ($lastlevel == 1) &&  push @toc, "\n";
		($lastlevel == 2) &&  push @toc, "</UL>\n";
		($lastlevel == 3) &&  push @toc, "</UL>\n";
		$lastlevel--;
	    };

	    # open new level?
	    while ( $level > $lastlevel ) {
		# ($lastlevel == 0) &&  push @toc, "\n";
		($lastlevel == 1) &&  push @toc, "<UL>\n";
		($lastlevel == 2) &&  push @toc, "<UL>\n";
		$lastlevel++;
	    };

	    # print list item	
	    # ($level == 1) && push @toc, "<P><A HREF=\"#$href\"> $buf </A></P>\n";
	    ($level == 2) && push @toc, "<LI><A HREF=\"#$href\"> $buf </A>\n";
	    ($level == 3) && push @toc, "<LI><A HREF=\"#$href\"> $buf </A>\n";
	};
    }

    # close any remaining levels
    while ( 0 < $lastlevel ) {
	# ($lastlevel == 1) &&  push @toc, "\n";
	($lastlevel == 2) &&  push @toc, "</UL>\n";
	($lastlevel == 3) &&  push @toc, "</UL>\n";
	$lastlevel--;
    };


    my $link_prd = expand ($html{link_product}, PRODUCT => $book{product});
    my $link_toc = expand ($html{link_toc}, BOOK => $book{name});
    my $link_prev = "Previous Chapter";
    my $link_next = "Next Chapter";
    my $link_idx = "";
    $link_idx .= expand ($html{link_bookidx}, BOOK => $book{name})
	if $book{bookidx};

    # no longer use master index
    #$link_idx .= expand ($html{link_mastidx}, FILE => $book{mastidx})
    # if $book{mastidx};
	

    if ($book{$file}->{prev}) {
	my $href = $book{$file}->{prev};
	my $name = $book{$href}->{title};
	$name =~ s/^\s*[0-9]+\s*//;  # strip number

	$link_prev = qq{<A HREF="$href" TITLE="$name">Previous Chapter</A>};
    }

    if ($book{$file}->{next}) {
	my $href = $book{$file}->{next};
	my $name = $book{$href}->{title};
	$name =~ s/^\s*[0-9]+\s*//;  # strip number

	$link_next = qq{<A HREF="$href" TITLE="$name">Next Chapter</A>};
    }


    # Add our title to the top, and add the chapter heading
    push @dst, expand ($html{header}, 
		       TITLE => $book{$file}->{title});

    push @dst, expand ($html{chapter}, 
		       TITLE => $book{$file}->{chapter},
		       PRODUCT => $book{product});

    # insert our top navigation bar
    push @dst, expand 
	($html{navbar_top}, 
	 LINK_PRODUCT => $link_prd,
	 LINK_TOC => $link_toc,
	 LINK_IDX => $link_idx,
	 LINK_NEXT => $link_next,
	 LINK_PREV => $link_prev);

    # add table of contents and the rest of the body
    push @dst, divwrap ("bktoc", $html{search}, @toc);
    push @dst, $html{main_start};

    while (@src) { 
	$_ = shift @src;
	# HACK - use this one last opportunity to compact out spaces
	# from markers in the preformatted blocks.
	s/(<A NAME="marker=[0-9]+">) (<\/A>)/$1$2/g;
	push @dst, $_; 
    }

    # insert our bottom navigation bar and copyright
    push @dst, $html{main_end};
    push @dst, expand 
	($html{navbar_bottom}, 
	 LINK_PRODUCT => $link_prd,
	 LINK_TOC => $link_toc,
	 LINK_IDX => $link_idx,
	 LINK_NEXT => $link_next,
	 LINK_PREV => $link_prev);

    push @dst, $html{copyright};
    push @dst, $html{footer};

    return @dst;
}

sub build_master_toc {
    my($bookname, @htmlfiles) = @_;
    local($_);
    local(*TOC);

    open (TOC, "> $outdir/$bookname.html");

    print TOC expand ($html{header}, TITLE => $book{title});
    print TOC expand ($html{banner}, TITLE => $book{title},
		      PRODUCT => $book{product});

    print TOC $html{maintoc_begin};
    for (@htmlfiles) {
	print TOC expand ($html{maintoc_entry},
			  TOCFILE => $_,
			  TOCBODY => $book{$_}->{title});
    }
    print TOC $html{maintoc_end};
    print TOC $html{copyright};
    print TOC $html{footer};
    close (TOC);
}


sub build_image_tag {
    my ($file,$alt) = @_;
    my $doinclude = $file =~ /^@/;

    $file =~ s/^@// if $doinclude;


    # <div class=figure><img src="images/vc10_libs.gif"></div>

    # Find the file
    my @paths = grep (-f "$_/$file", @image_paths);
    my $path = $paths[0];

    # print "WARNING: Multiple copies of $file (in ", join(',',@paths), ")\n" 
    #  if scalar(@paths) > 1;

    # replace with contents of the referenced file
    if ($doinclude) {
	print "INCLUDING html: $path/$file\n";

	($path && open (SRC, "$path/$file")) || do {
	    print "WARNING: Could not include $file\n";
	    return "";
	};
	my $tag = join '', <SRC>;
	close (SRC);
	return $tag;
    }

    # Substitute normal image file, get the image dimensions and copy
    # the file from wherever we found it to the output area.
    my $tag = "<IMG SRC=\"images/$file\"";

    if ($path) {
	print "USING image: $path/$file\n";

#	my $info = image_info("$path/$file");
	my $imgdir = "$outdir/images";

#	my ($w, $h) = dim($info);
#	$tag .= " WIDTH=$w HEIGHT=$h"	
#	    if ($w!=0 || $h!=0);

#	print "WARNING: Can't compute image metrics for $file\n" 
#	    if ($w==0 || $h==0);

	# try to copy the images over to a local images directory.
	-d $imgdir or mkpath ($imgdir) or die ("Can not create $imgdir");

	# Do a straight copy, do not worry about file line conventions,
	# which means that this should work fine for binary files.
	#
	-f "$imgdir/$file" and (unlink "$imgdir/$file" 
	     or die "Can not remove $file in $imgdir");

	copy ("$path/$file", "$imgdir/$file") or die "Can not copy $file";
    }

    # make the alt text nice
    $alt =~ s/\s+$//;
    $alt =~ s/^s+//;
    $alt =~ s/\s\s+/ /g;

    $tag .= " ALT=\"$alt\"" if ($alt ne "");
    $tag .= ">";

    return $tag;
}





sub main {
    my @files;

    while ($_[0]) {
	$_ = $_[0];

	/^-help$/ && &usage;
	/^-src$/ && do {
	    $srcdir = $_[1] or die "error: need -src <name>";
	    shift; shift; 
	    next;
	};

	/^-o$/ && do {
	    $outdir = $_[1] or die "error: need -o <name>";
	    shift; shift; 
	    next;
	};


	/^-/ && die "$0: unknown option: $_ (use -help for usage)\n";

	push @files, $_;  # tack on as just a plain file
	shift;
    }

    # Append the default paths
    push @image_paths, (".",
			"$outdir/images_html", 
			"$outdir/images", 
			"images_html",
			"images",
			);

    # Pre-expand with the current year and links
    $html{header} = expand ($html{header}, 
			    STYLE => $book{csslink});

    $html{copyright} = expand ($html{copyright},
			       YEAR => $book{year},
			       COPYRIGHT => $book{crlink});

    -d $outdir or mkpath ($outdir) or 
	die ("WARNING: Can not create $outdir\n");


    for (@files) {
	my $file= $_;
	my @lines = scan_htmlfile ($file, $file);
	local(*DST);

	print (STDOUT "$file: Processing headers\n");
	@lines = correct_header_entries ($file, @lines);

	print (STDOUT "$file: Processing image tags\n");
	@lines = correct_image_entries ($file, @lines);

	print (STDOUT "$file: Merging and correcting\n");
	@lines = correct_paragraph_styles ($file, @lines);

	print (STDOUT "$file: Building TOC\n");
	@lines = build_chapter_toc ($file, @lines);

	open (DST, "> $outdir/$file") or die "could not write $file";
	print DST @lines;
	close (DST);
    }

    return 1;
}

$html{footer} = "</BODY>\n</HTML>\n";
$html{header} = <<'PERL_EOF';
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<HTML>
<HEAD>
   <TITLE>%%TITLE%%</TITLE>
   <link rel="stylesheet" type="text/css" href="%%STYLE%%">
</HEAD>
<BODY>
PERL_EOF
    ;

$html{chapter} = <<'PERL_EOF';
<TABLE class=bkhead><TR>
<TD class=logo>%%TITLE%%</TD>
<TD class=quicklinks>
  <A HREF="../index.html">[%%PRODUCT%% Home]</A>
  <A HREF="http://www.steptools.com">[www.steptools.com]</a>
</TD></TR>
</TABLE>
PERL_EOF
    ;

$html{banner} = <<'PERL_EOF';
<TABLE class=pagehead><TR>
<TD class=logo>%%TITLE%%</TD>
<TD class=quicklinks>
  <A HREF="../index.html">[%%PRODUCT%% Home]</A>
  <A HREF="http://www.steptools.com">[www.steptools.com]</a>
</TD></TR>
</TABLE>
PERL_EOF
    ;

$html{main_start} = qq{<div class=main>\n};
$html{main_end}   = qq{</div>\n};


$html{copyright} = <<'PERL_EOF';
<div class="copyright">
  Copyright &#169; %%YEAR%% STEP Tools Incorporated. All Rights Reserved.<br>
<A HREF="%%COPYRIGHT%%">Legal notices and trademark attributions.</A>
</div>
PERL_EOF
    ;

$html{navbar_top} = <<'PERL_EOF';
<div class=bknavtop>
  %%LINK_TOC%% | %%LINK_IDX%%
  %%LINK_PREV%% | 
  %%LINK_NEXT%%
</div>
PERL_EOF

$html{navbar_bottom} = <<'PERL_EOF';
<div class=bknavbot>
| %%LINK_TOC%% | %%LINK_IDX%%
  %%LINK_PRODUCT%% |
  %%LINK_PREV%% | 
  %%LINK_NEXT%% |
</div>
PERL_EOF

# Note that we are using qq{} to quote strings to avoid endless
# escaping of single quotes.
#
$html{indent}		= "    ";
$html{alert}		= qq{<IMG SRC="../images/alert.gif" WIDTH=55 HEIGHT=40 ALT=Alert>};
$html{link}		= qq{<A HREF="%%FILE%%">%%NAME%%</A>};
$html{section_one_rule} = qq{<HR ALIGN=LEFT WIDTH="50%">\n};
$html{section_two_rule} = qq{<HR ALIGN=LEFT WIDTH="25%">\n};

$html{maintoc_begin}	= $html{main_start} . qq{<UL>\n};
$html{maintoc_end}	= qq{</UL>\n} . $html{main_end};
$html{maintoc_entry}	= qq{<LI><A HREF="%%TOCFILE%%">\t%%TOCBODY%%</A>\n};

# The index link is optional, so we include the vertical bar separator
# here.  If it is ever used in another context, we will have to factor
# that out to the substitution.
$html{link_product}	= qq{<A HREF="../index.html">%%PRODUCT%% Home</A>};
$html{link_toc}		= qq{<A HREF="%%BOOK%%.html">Book Contents</A>};
$html{link_bookidx}	= qq{<A HREF="%%BOOK%%_index.html">Book Index</A> | };
$html{link_mastidx}	= qq{<A HREF="%%FILE%%">Master Index</A> | };

$html{search} = <<'PERL_EOF';
<FORM class=bksearch method=GET action="http://www.google.com/search">
Search STEP Tools Web Support
<INPUT TYPE=text name=q size=22 maxlength=255 value="">
<INPUT TYPE=hidden name=q value="site:www.steptools.com/support">
<INPUT class=button type=submit name=sa VALUE="Google">
</FORM>
PERL_EOF
    ;

main(@ARGV);
