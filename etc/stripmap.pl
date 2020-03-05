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

use strict;

my $do_scanonly=0;

#----------------------------------------
# finds the bug number and tags the file if it does not have one
#
sub renum_toc_entries {
    my($file) = @_;

    my $bakfile = "$file~";
    my $changed = 0;
    my @contents;

    local ($_);
    local(*SRC);
    
    open (SRC, $file) or die "could not open $file";

    my $intbl = 0;
    my $armtag = undef;

    while (<SRC>) {
	
	/<TD><P CLASS=\"MapARM\">(.+)<\/P>/ && do {
	    my $ao = $1;
	    my $tag = lc $ao;
	    $tag =~ s/\s+$//;
	    $tag =~ s/^\s+//;
	    $tag =~ s/\s+/-/;
	    $tag = 'map-' . $tag;
	    $armtag = $tag;
	    $changed = 1;

	    push @contents, "</table>\n" if $intbl;

	    push @contents, "\n\n<!-- ============================== -->\n";
	    push @contents, "<H4><A NAME=\"$tag\"></A>5.1.1.1 $ao</H4>\n";

	    my $indiv = 0;
	    while (not /<\/TD>/) {
		$_ = <SRC>;
		/<P[^>]*>(.+)<\/P>/ && do {
		    push @contents, "<div class=\"mapnote\">\n" if not $indiv;
		    push @contents, "<p>$1</p>\n";
		    $indiv = 1;
		};
	    }
	    push @contents, "</div>\n" if $indiv;
	    push @contents, "\n<table class=\"map\">\n";
	    $intbl = 1;
	    next; 
	};


	/<TD><P CLASS=\"MapAttribute\">(.+)<\/P>/ && do {
	    my $ao = $1;
	    my $tag = lc $ao;
	    $tag =~ /\(\s*as\s+([^\)]+)/ && do { $tag = $1; };
	    print "NEED name for $tag\n" if $tag =~ /\s+to\s+/;
	    
	    $tag =~ s/\s+$//;
	    $tag =~ s/^\s+//;
	    $tag =~ s/\s+/-/;
	    $tag = "$armtag-$tag";
	    $changed = 1;

	    push @contents, "</table>\n" if $intbl;

	    push @contents, "\n\n";
	    push @contents, "<H5><A NAME=\"$tag\"></A>5.1.1.1.1 $ao</H5>\n";

	    my $indiv = 0;
	    while (not /<\/TD>/) {
		$_ = <SRC>;
		/<P[^>]*>(.+)<\/P>/ && do {
		    push @contents, "<div class=\"mapnote\">\n" if not $indiv;
		    push @contents, "<p>$1</p>\n";
		    $indiv = 1;
		};
	    }
	    push @contents, "</div>\n" if $indiv;
	    push @contents, "\n<table class=\"map\">\n";
	    $intbl = 1;
	    next; 
	};

	/<TD><P CLASS=\"MapAIM\">(.+)<\/P>/ && do {
	    my $body = $1;
	    if (not $intbl) {
		print "Warning not in table!  $body\n";
		push @contents, "\n\n<!-- WARNING NOT IN TABLE -->\n";
	    }

	    push @contents, "<tr><th>AIM element:</th>\n";
	    push @contents, "<td>$body";

	    while (not /<\/TD>/) {
		$_ = <SRC>;
		/<P[^>]*>(.+)<\/P>/ && do {
		    push @contents, "\n$1";
		};
	    }
	    push @contents, "</td>\n</tr>\n";
	    next; 
	};


	/<TD><P CLASS=\"MapPath\">(.+)<\/P>/ && do {
	    my $body = $1;
	    if (not $intbl) {
		print "Warning not in table!  $body\n";
		push @contents, "\n\n<!-- WARNING NOT IN TABLE -->\n";
	    }

	    push @contents, "\n<tr><th>Reference path:</th>\n";
	    push @contents, "<td class=\"path\">$body";

	    while (not /<\/TD>/) {
		$_ = <SRC>;
		/<P[^>]*>(.+)<\/P>/ && do {
		    push @contents, "\n$1";
		};

		# rule tags mixed in
		if (/<H6/ and not /<\/H6>/) { chomp; $_.= <SRC>; }
		/<H6[^>]*>(.+)<\/H6>/ && do {
		    push @contents, "\n$1";
		};
	    }
	    push @contents, "\n</td>\n</tr>\n";
	    next; 
	};

	/<TD><H6 CLASS=\"MapSource\">(.+)<\/H6>/ && do {
	    my $body = $1;
	    if (not $intbl) {
		print "Warning not in table!  $body\n";
		push @contents, "\n\n<!-- WARNING NOT IN TABLE -->\n";
	    }

	    push @contents, "\n<tr><th>Source:</th>\n";
	    push @contents, "<td>$body";

	    while (not /<\/TD>/) {
		$_ = <SRC>;
		/<H6[^>]*>(.+)<\/H6>/ && do {
		    push @contents, "\n$1";
		};
	    }
	    push @contents, "</td>\n</tr>\n";
	    next; 
	};

	/<TD><H6 CLASS=\"MapRules\">/ && do {
	    
	    if (not /<\/H6>/) { chomp; $_.= <SRC>; }
	    my ($body) = /<TD><H6 CLASS=\"MapRules\">(.+)<\/H6>/;
	    if (not $intbl) {
		print "Warning not in table!  $body\n";
		push @contents, "\n\n<!-- WARNING NOT IN TABLE -->\n";
	    }

	    push @contents, "\n<tr><th>Rules:</th>\n";
	    push @contents, "<td>$body";

	    while (not /<\/TD>/) {
		$_ = <SRC>;
		if (/<H6/ and not /<\/H6>/) { chomp; $_.= <SRC>; }

		/<H6[^>]*>(.+)<\/H6>/ && do {
		    push @contents, "\n$1";
		};
	    }
	    push @contents, "</td>\n</tr>\n";
	    next; 
	};


	/^\s*<TR>\s*$/ && do { 
	    $changed = 1;
	    next; 
	};
	/^\s*<\/TR>\s*$/ && do { 
	    $changed = 1;
	    push @contents, "</table>\n" if $intbl;
	    $intbl = 0;
	    next; 
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

sub main {
    my @files;
    
    while ($_[0]) {
	$_ = $_[0];

	/^-help$/ && &usage;

	/^-n$|^-scan$/ && do {
	    $do_scanonly=1;
	    shift; next;
	};

	/^--$/ && do {
	    shift; 
	    push @files, @_;  # tack on all remaining
	    last;
	};

	/^-/ && die "$0: unknown option: $_ (use -help for usage)\n";

	push @files, $_;  # tack on as just a plain file
	shift;
    }

    foreach (@files) {
	renum_toc_entries ($_);
    }
    return 1;
}

main (@ARGV);

#
