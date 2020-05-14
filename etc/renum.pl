#!/usr/local/bin/perl
# 
# Copyright (c) 1991-2020 by STEP Tools Inc. 
# All Rights Reserved.
# 
# Permission to use, copy, modify, and distribute this software and
# its documentation is hereby granted, provided that this copyright
# notice and license appear on all copies of the software.
# 
# STEP TOOLS MAKES NO REPRESENTATIONS OR WARRANTIES ABOUT THE
# SUITABILITY OF THE SOFTWARE, EITHER EXPRESS OR IMPLIED, INCLUDING
# BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT. STEP TOOLS
# SHALL NOT BE LIABLE FOR ANY DAMAGES SUFFERED BY LICENSEE AS A
# RESULT OF USING, MODIFYING OR DISTRIBUTING THIS SOFTWARE OR ITS
# DERIVATIVES.
# 
# Author: David Loffredo (loffredo@steptools.com)
# 
# Renumber clauses in document.

# Can renumber the anchors in one pass, we need to renumber the
# references in a second pass.


use strict;
my %anchor;
my $fignum = 0;
my $tabnum = 0;


my @files = (
    "foreword.htm",
    "introduction.htm",
    "clause1.htm",
    "clause2.htm",
    "clause3.htm",
    "clause4.htm",
    "clause5.htm",
    "clause6.htm",
    "annexA.htm",
    "annexB.htm",
    "annexC.htm",
    "annexD.htm",
    "annexE.htm",
    "annexF.htm",
    "annexG.htm",
    "annexH.htm",
    "annexI.htm",
    "annexJ.htm",
    "annexK.htm",
    "bibliography.htm"
 );

my $do_scanonly=0;

sub renum_anchors {
    my($file) = @_;

    # scan anchors and update numbering if needed.  We also build a
    # dictionary with the updated anchor text.
    #
    my $bakfile = "$file~";
    my $changed = 0;
    my @contents;
    my @sec;

    local ($_);
    local(*SRC);
    
    open (SRC, $file) or die "could not open $file";
    print "Scanning $file\n";
    
    while (<SRC>) {
	/^<FIGURE ID=\"([^\"]+)\">/i && do {
	    my $tag = $1;
	    my $url = "$file#$tag";
	    warn "Duplicate anchor $tag" if exists $anchor{$url};

	    my $num = ++$fignum;  ## Prepend annex if in an annex file
	    $num = "$sec[0].$num" if  $sec[0] =~ /[A-Z]/;

	    
	    while (not /<\/FIGURE>/i) {
		push @contents, $_;
		$_ = <SRC>;

		if (/<FIGCAPTION>(.*)<\/FIGCAPTION>/i) {
		    my $orig = $_;
		    my $body = $1;
		    $body =~ s/^\s*Figure\s+([A-Z]\.)?\d+\s*&mdash;\s*//;
		    $anchor{$url} = {
			num => "Figure $num",
			txt => $body,
			cap => "Figure $num &mdash; $body"
		    };
		    $_ = "<FIGCAPTION>$anchor{$url}->{cap}</FIGCAPTION>\n";

		    if ($orig ne $_) {
			$changed = 1;
			print "RENUM $anchor{$url}->{cap}\n";
		    }
		}
	    }
	};

	/^<CAPTION ID=\"([^\"]+)\">(.*)<\/CAPTION>/i && do {
	    my $tag = $1;
	    my $body = $2;
	    my $orig = $_;
	    my $url = "$file#$tag";
	    warn "Duplicate anchor $tag" if exists $anchor{$url};

	    my $num = ++$tabnum;  ## Prepend annex if in an annex file
	    $num = "$sec[0].$num" if  $sec[0] =~ /[A-Z]/;

	    $body =~ s/^\s*Table\s+([A-Z]\.)?\d+\s*&mdash;\s*//;
	    $body =~ s/\s*$//;
	    $anchor{$url} = {
		num => "Table $num",
		txt => $body,
		cap => "Table $num &mdash; $body"
	    };
	    $_ = "<CAPTION ID=\"$tag\">$anchor{$url}->{cap}</CAPTION>\n";

	    if ($orig ne $_) {
		$changed = 1;
		print "RENUM $anchor{$url}->{cap}\n";
	    }
	};

	/^<H1 ID=\"([^\"]+)\" CLASS=\"(clause|unum|annex)\">(.*)<\/H1>/i && do {
	    my $tag = $1;
	    my $cls = $2;
	    my $body = $3;
	    my $url = "$file#$tag";
	    warn "Duplicate anchor $tag" if exists $anchor{$url};

	    $body =~ s/\s*$//;
	    @sec = $body =~ /^\s*(\d+)\s+/ if $cls eq 'clause';
	    @sec = $body =~ /^\s*Annex\s+([A-Z])/ if $cls eq 'annex';
	    @sec = () if $cls eq 'unum';

	    $fignum = 0 if $cls eq 'annex';
	    $tabnum = 0 if $cls eq 'annex';

	    
	    my $num =  (join '.', @sec);
	    $anchor{$url} = {
		num => $num,
		txt => $body,
		cap => "$num $body"
	    };

	    # Top level renumber manually if needed.
	};

	/^<H([2-6]) ID=\"([^\"]+)\">(.*)/i && do {
	    my $lev = $1;
	    my $tag = $2;
	    my $body = $3;
	    my $url = "$file#$tag";
	    warn "Duplicate anchor $tag" if exists $anchor{$url};

	    # strip close and old clause number
	    $body =~ s/<\/H$lev>\s*$//;  # strip close
	    $body =~ s/^\s*((\d+|[A-Z])\.[\d\.]+)*\s+//;  
	    my $oldsec = $1;
	    
	    if ((scalar @sec) > $lev) {
		splice @sec, $lev;  # shrink
	    }
	    while ((scalar @sec) < $lev) {
		push @sec, 0;  # grow
	    }

	    my $cnt = pop @sec;
	    push @sec, $cnt+1;

	    my $num = (join '.', @sec);
	    $anchor{$url} = {
		num => $num,
		txt => $body,
		cap => "$num $body"
	    };
	    
	    $_ = "<H$lev ID=\"$tag\">$num $body</H$lev>\n";
	    if ($num ne $oldsec) {
		print "Changed: $oldsec  --> $num\n";
		$changed = 1;
	    }
	};
	
	
	push @contents, $_;
    }
    close (SRC);


    if ($changed && !$do_scanonly) {
	# extract it if it is not present;
	print "$file: writing updated file\n";

	rename $file, $bakfile	or die ("$bakfile: $!");
	open (DST, "> $file")	or die ("$file: $!");
	print DST @contents	or die ("$file: $!");
	close DST		or die ("$file: $!");
#	unlink $bakfile		or die ("$bakfile: $!");
    }

}


sub rewrite_anchor {
    my($optag, $body, $endtag, $file) = @_;
    my $asis = "$optag$body$endtag";

    my ($href) =  $optag =~ /HREF=\"([^\"]+)/i;
    return $asis if not defined $href;

    
    my $url = $href;
    $url = $file . $url if $url =~ /^#/;
    return $asis if not exists $anchor{$url};

    my $td = $anchor{$url};

    if ($url =~ /#fig-/) {
	print "Updating $body to $td->{num}\n" if $body ne $td->{num};
	return $optag. $td->{num} . $endtag;
    }

    if ($url =~ /#table-/) {
	print "Updating $body to $td->{num}\n" if $body ne $td->{num};
	return $optag. $td->{num} . $endtag;
    }

    # use class on href to force content to clause or name
    my ($cls) =  $optag =~ /CLASS=\"([^\"]+)/i;
    ($cls) = $optag =~ /CLASS=([^\s>]+)/i if not defined $cls;
    return $asis if not defined $cls;

    if ($cls =~ /refnum/) {
	print "Updating $body to $td->{num}\n" if $body ne $td->{num};
	return $optag. $td->{num} . $endtag;
    }

    if ($cls =~ /reftxt/) {
	print "Updating $body to $td->{txt}\n" if $body ne $td->{txt};
	return $optag. $td->{txt} . $endtag;
    }

    return $asis;
}



sub renum_refs {
    my($file) = @_;

    # scan anchors and update numbering if needed.  We also build a
    # dictionary with the updated anchor text.
    #
    my $bakfile = "$file~";
    my $changed = 0;
    my @contents;
    my @sec;

    local ($_);
    local(*SRC);
    
    open (SRC, $file) or die "could not open $file";
    print "Updating refs $file\n";
    
    while (<SRC>) {
	my $orig = $_;
	# this uses code that fell to earth from space to do a minimal match
	s/(<A\s[^>]*>)((?:(?!<A\s).)*)(<\/A>)/rewrite_anchor($1,$2,$3,$file)/egisx;

	#print "$orig\n$_" if $orig ne $_;
	$changed = 1 if $orig ne $_;
	push @contents, $_;
    }
    close (SRC);


    if ($changed && !$do_scanonly) {
	# extract it if it is not present;
	print "$file: writing updated file\n";

	rename $file, $bakfile	or die ("$bakfile: $!");
	open (DST, "> $file")	or die ("$file: $!");
	print DST @contents	or die ("$file: $!");
	close DST		or die ("$file: $!");
#	unlink $bakfile		or die ("$bakfile: $!");
    }

}





sub main {
    while ($_[0]) {
	$_ = $_[0];
	/^-n$|^-scan$/ && do {
	    $do_scanonly=1;
	    shift; next;
	};

	/^-/ && die "$0: unknown option: $_ (use -help for usage)\n";

	push @files, $_;  # tack on as just a plain file
	shift;
    }

    foreach (@files) { renum_anchors ($_); }
    foreach (@files) { renum_refs ($_); }
    return 1;
}

main (@ARGV);

