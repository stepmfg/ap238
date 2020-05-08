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
# Convert anchors from <A NAME=""> to <Hx ID=""> because name is
# obsolete in HTML5



use strict;
my %anchor;
my $fignum = 0;
my $tabnum = 0;


my @files = (
    "abstract.htm",
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

sub reformat_anchors {
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
	/^<FIGURE><A NAME=\"([^\"]+)\"><\/A>/i && do {
	    print "FIGURE $1\n";
	    s/^<FIGURE><A NAME=\"([^\"]+)\"><\/A>/<FIGURE ID="$1">/i;
	    $changed = 1;
	};

	/^<CAPTION><A NAME=\"([^\"]+)\"><\/A>/i && do {
	    print "CAPTION $1\n";
	    s/^<CAPTION><A NAME=\"([^\"]+)\"><\/A>/<CAPTION ID="$1">/i;
	    $changed = 1;
	};

	/^<LI><A NAME=\"([^\"]+)\"><\/A>/i && do {
	    print "LIST $1\n";
	    s/^<LI><A NAME=\"([^\"]+)\"><\/A>/<LI ID="$1">/i;
	    $changed = 1;
	};

	/^<H1 CLASS=\"(clause|unum|annex)\"><A NAME=\"([^\"]+)\"><\/A>/i && do {
	    print "CLAUSE $2, $1\n";
	    s/^<H1 CLASS=\"(clause|unum|annex)\"><A NAME=\"([^\"]+)\"><\/A>/<H1 ID="$2" CLASS="$1">/i;
	    $changed = 1;
	};

	/^<H([2-6])><A NAME=\"([^\"]+)\"><\/A>/ && do {
	    print "SUBCLAUSE $2\n";
	    s/^<H([2-6])><A NAME=\"([^\"]+)\"><\/A>/<H$1 ID="$2">/i;
	    $changed = 1;
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

    foreach (@files) { reformat_anchors ($_); }
    return 1;
}

main (@ARGV);

