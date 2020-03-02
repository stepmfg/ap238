#!/usr/local/bin/perl
# 
# Copyright (c) 1991-2017 by STEP Tools Inc. 
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
my $do_scanonly=0;
my %html;

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

sub gen_armidx {
    my($file, $dst) = @_;

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
    open (DST, "> $dst") or die "could not open $dst";
    
    print "Scanning $file\n";
    print DST $html{armhead};
    print DST "<TABLE class=\"altrow\">\n";
    
    while (<SRC>) {
	/^<H3><A NAME=\"ao-([^\"]+)\"><\/A>(.*)/ && do {
	    my $tag = $1;
	    my $body = $2;
	    $body =~ s/<\/H3>\s*$//;
	    $body =~ s/^\s*((\d+|[A-Z])\.[\d\.]+)*\s+//;  

	    my $armid = lc $tag;
	    print DST "<TR><TD>$body</TD>\n";
	    print DST "<TD><A HREF=\"clause4.htm#ao-$tag\">AO</a></TD>\n";
	    print DST "<TD><A HREF=\"clause5.htm#map-$tag\">Map</a></TD>\n";
	    print DST "<TD><A HREF=\"annexG.htm#$armid\">ARM</a></TD>\n";
	    print DST "</TR>\n";
	};
    }
    print DST "</TABLE>\n";
    print DST $html{tail};

    close (DST);
    close (SRC);
}




sub main {
    while ($_[0]) {
	$_ = $_[0];
	/^-n$|^-scan$/ && do {
	    $do_scanonly=1;
	    shift; next;
	};

	/^-/ && die "$0: unknown option: $_ (use -help for usage)\n";

	shift;
    }

    
    gen_armidx ("clause4.htm", "idxarm.htm");
    return 1;
}

$html{armhead} = <<'PERL_EOF';
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>ISO 10303-238</title>

<link rel="stylesheet" href="style.css">
</head>
<body>
<p class=pagehead>ISO/DIS 10303-238</p>

<H1 CLASS="unum">Application Object Index</H1>

PERL_EOF
    ;

$html{tail} = <<'PERL_EOF';

<p class=pagefoot>&copy; ISO 2020 &mdash; All rights reserved
</body>
</html>
PERL_EOF
    ;

main (@ARGV);

