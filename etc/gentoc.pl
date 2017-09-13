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
my $maxdepth=2;
my %html;
my @figs;
my @tables;

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
    my $depth;
    
    local ($_);
    local(*SRC);
    
    open (SRC, $file) or die "could not open $file";

    while (<SRC>) {
	/^<H2 CLASS=\"clause\"><A NAME=\"clause-(\d+)\"><\/A>(.*)/ && do {
	    my $tag = $1;
	    my $body = $2;
	    $body =~ s/<\/H2>\s*$//;

	    print "CLAUSE $tag -- $body\n";
	    while ($depth > 0) {
		$depth--;
		print DST "</UL>\n";
		print DSTFRM "</UL>\n";
	    }
	    print DST "\n<LI CLASS=clause><a href=\"$file\">$body</A></LI>\n";
	    print DSTFRM "\n<LI CLASS=clause><a href=\"$file\" target=\"body\">$body</A></LI>\n";	    
	};

	/^<H2 CLASS=\"annex-clause\"><A NAME=\"clause-([A-Z])\"><\/A>(.*)/ && do {
	    my $tag = $1;
	    my $body = $2;
	    $body =~ s/<\/H2>\s*$//;
	    $body =~ s/<BR>/ /g;

	    print "CLAUSE $tag -- $body\n";
	    while ($depth > 0) {
		$depth--;
		print DST "</UL>\n";
		print DSTFRM "</UL>\n";
	    }
	    print DST "<LI CLASS=clause><a href=\"$file\">$body</A></LI>\n";
	    print DSTFRM "<LI CLASS=clause><a href=\"$file\" target=\"body\">$body</A></LI>\n";	    
	};


	
	/^<H2 CLASS=\"unum\"><A NAME=\"([^\"]+)\"><\/A>(.*)/ && do {
	    my $tag = $1;
	    my $body = $2;
	    $body =~ s/<\/H2>\s*$//;

	    print "CLAUSE $tag -- $body\n";
	    while ($depth > 0) {
		$depth--;
		print DST "</UL>\n";
		print DSTFRM "</UL>\n";
	    }
	    print DST "<LI CLASS=clause><a href=\"$file\">$body</A></LI>\n";
	    print DSTFRM "<LI CLASS=clause><a href=\"$file\" target=\"body\">$body</A></LI>\n";	    
	};




	    
	/^<H3><A NAME=\"clause-(([A-Z]|\d+)-[\d-]+)\"><\/A>(.*)/ && do {
	    my $tag = $1;
	    my $body = $3;
	    $body =~ s/<\/H3>\s*$//;

	    my $tagdepth = () = $tag =~ /-/g;

	    next if $tagdepth > $maxdepth;
	    
	    while ($depth < $tagdepth) {
		$depth++;
		print DST "<UL>\n";
		print DSTFRM "<UL>\n";
	    }
	    
	    while ($depth > $tagdepth) {
		$depth--;
		print DST "</UL>\n";
		print DSTFRM "</UL>\n";
	    }

	    print "CLAUSE $tag -- $body\n";
	    print DST "<LI><a href=\"$file#clause-$tag\">$body</A></LI>\n";
	    print DSTFRM "<LI><a href=\"$file#clause-$tag\" target=\"body\">$body</A></LI>\n";	    
	};

	/^<FIGCAPTION><A NAME=\"([^\"]+)\"><\/A>(.*)/ && do {
	    my $tag = $1;
	    my $body = $2;
	    $body =~ s/<\/FIGCAPTION>\s*$//;

	    print "FIGURE $tag -- $body\n";

	    push @figs, "<LI><a href=\"$file#$tag\"%%TARGET%%>$body</A></LI>\n";
	};
    }

    
    while ($depth > 0) {
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

    print DST $html{tail};
    print DSTFRM $html{tail};

    close (DST);
    close (DSTFRM);


    print "Installing new index files\n";
    rename 'contents.htm', 'oldtoc.htm' or die ("old toc: $!");
    rename 'newtoc.htm', 'contents.htm'	or die ("new toc: $!");

    rename 'frameindex.htm', 'oldtocfrm.htm' or die ("old frm: $!");
    rename 'newtocfrm.htm', 'frameindex.htm' or die ("old frm: $!");
    
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

<div class=contents>

<H2 CLASS="unum">Contents</H2>
<UL>
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

<div class=contents>

<UL>
<li class=clause><a href="index.htm" target="_parent">Cover</a>
PERL_EOF
    ;


$html{endtoc} = <<'PERL_EOF';
</UL>

<H2 CLASS="unum">Figures</H2>
<UL>
PERL_EOF
    ;


$html{tail} = <<'PERL_EOF';
</UL>

<H2 CLASS="unum">Tables</H2>
<UL>
</UL>


</div>

<p class=pagefoot>Document TC184/SC4/WG15 Nxxx
</body>
</html>
PERL_EOF
    ;


main (@ARGV);

