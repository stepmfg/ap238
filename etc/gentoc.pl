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
# Generate Table of Contents
# 

use strict;

my $do_scanonly=0;
my $maxdepth=3;
my %html;
my @figs;
my @tabs;

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

local(*DST);
local(*DSTFRM);


#----------------------------------------
# finds the bug number and tags the file if it does not have one
#

## Scan for tables and figures too

sub scan_toc_entries {
    my($file) = @_;

    my $bakfile = "$file~";
    my $changed = 0;
    my $depth = 1;
    
    local ($_);
    local(*SRC);
    
    open (SRC, $file) or die "could not open $file";

    while (<SRC>) {
	/^<H1 CLASS=\"(clause|unum|annex)\"><A NAME=\"([^\"]+)\"><\/A>(.*)/ && do {
	    my $cls = $1;
	    my $tag = $2;
	    my $body = $3;
	    $body =~ s/<\/H1>\s*$//;
	    $body =~ s/<BR>/ /g;

	    print "CLAUSE $tag -- $body\n";
	    while ($depth > 1) {
		$depth--;
		print DST "</UL>\n";
		print DSTFRM "</UL>\n";
	    }
	    print DST "<LI CLASS=clause><a href=\"$file\">$body</A></LI>\n";
	    print DSTFRM "<LI CLASS=clause><a href=\"$file\" target=\"body\">$body</A></LI>\n";	    
	};


	/^<H([2-6])><A NAME=\"([^\"]+)\"><\/A>(.*)/ && do {
	    my $lev = $1;
	    my $tag = $2;
	    my $body = $3;
	    $body =~ s/<\/H$lev>\s*$//;

	    next if $lev > $maxdepth;
	    
	    while ($depth < $lev) {
		$depth++;
		print DST "<UL>\n";
		print DSTFRM "<UL>\n";
	    }
	    while ($depth > $lev) {
		$depth--;
		print DST "</UL>\n";
		print DSTFRM "</UL>\n";
	    }
	    
	    print "CLAUSE $tag -- $body\n";
	    print DST "<LI><a href=\"$file#$tag\">$body</A></LI>\n";
	    print DSTFRM "<LI><a href=\"$file#$tag\" target=\"body\">$body</A></LI>\n";	    
	};

	/^<FIGURE><A NAME=\"([^\"]+)\"><\/A>/ && do {
	    my $tag = $1;
	    my $body;

	    while (not /<\/FIGURE>/) {
		$_ = <SRC>;
		$body = $1 if /<FIGCAPTION>(.*)<\/FIGCAPTION>/;
	    }

	    print "FIGURE $tag -- $body\n";
	    push @figs, "<LI><a href=\"$file#$tag\"%%TARGET%%>$body</A></LI>\n";
	};

	/^<CAPTION><A NAME=\"([^\"]+)\"><\/A>(.*)/ && do {
	    my $tag = $1;
	    my $body = $2;
	    $body =~ s/<\/CAPTION>\s*$//;

	    print "TABLE $tag -- $body\n";

	    push @tabs, "<LI><a href=\"$file#$tag\"%%TARGET%%>$body</A></LI>\n";
	};
    }

    
    while ($depth > 1) {
	$depth--;
	print DST "</UL>\n";
	print DSTFRM "</UL>\n";
    }
    close (SRC);
}

sub main {
    while ($_[0]) {
	$_ = $_[0];

	/^-help$/ && &usage;

	/^-n$|^-scan$/ && do {
	    $do_scanonly=1;
	    shift; next;
	};

	/^-/ && die "$0: unknown option: $_ (use -help for usage)\n";
	shift;
    }

    open (DST, "> newtoc.htm") or die "could not open toc";
    open (DSTFRM, "> newtocfrm.htm") or die "could not open tocfrm";

    print DST $html{tochead};
    print DSTFRM $html{framehead};
    
    foreach (@files) {
	scan_toc_entries ($_);
    }

    print DST $html{endtoc};
    print DSTFRM $html{endtoc};

    foreach (@figs) {
	my ($f1, $f2) = ($_, $_);
	$f1 =~ s/%%TARGET%%//;
	$f2 =~ s/%%TARGET%%/ target="body"/;
	print DST $f1;
	print DSTFRM $f2;
    }

    print DST $html{endfig};
    print DSTFRM $html{endfig};

    foreach (@tabs) {
	my ($f1, $f2) = ($_, $_);
	$f1 =~ s/%%TARGET%%//;
	$f2 =~ s/%%TARGET%%/ target="body"/;
	print DST $f1;
	print DSTFRM $f2;
    }

    print DST $html{tail};
    print DSTFRM $html{tail};

    close (DST);
    close (DSTFRM);
    
    print "Installing new index files\n";
    rename 'contents.htm', 'contents.htm~' or die ("old toc: $!");
    rename 'newtoc.htm', 'contents.htm'	or die ("new toc: $!");

    rename 'frameindex.htm', 'frameindex.htm~' or die ("old frm: $!");
    rename 'newtocfrm.htm', 'frameindex.htm' or die ("new frm: $!");
    
    return 1;
}


$html{tochead} = <<'PERL_EOF';
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>ISO 10303-238</title>
<link rel="stylesheet" href="style.css">
</head>
<body>
<p class=pagehead>ISO 10303-238</p>

<H1 CLASS="unum">Contents</H1>

<div class=contents>
<UL>
<li class=clause><a href="idxarm.htm">Application Object Index</a>
PERL_EOF
    ;


$html{framehead} = <<'PERL_EOF';
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>ISO 10303-238</title>
<link rel="stylesheet" href="style.css">
</head>
<body>

<div class="contents side">
<UL>
<li class=clause><a href="index.htm" target="_parent">Cover</a>
<li class=clause><a href="idxarm.htm" target="body">Application Object Index</a>
PERL_EOF
    ;


$html{endtoc} = <<'PERL_EOF';
</UL>

<H1 CLASS="unum">Figures</H1>
<UL>
PERL_EOF
    ;


$html{endfig} = <<'PERL_EOF';
</UL>

<H1 CLASS="unum">Tables</H1>
<UL>
PERL_EOF
    ;

$html{tail} = <<'PERL_EOF';
</UL>


</div>

<p class=pagefoot>&copy; ISO 2020 &mdash; All rights reserved
</body>
</html>
PERL_EOF
    ;


main (@ARGV);

