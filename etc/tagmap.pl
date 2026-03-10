#!/usr/local/bin/perl
# 
# Copyright (c) 1991-2026 by STEP Tools Inc. 
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
# Add HTML markup to plain text mapping listings

use strict;
use File::Basename;

sub tagmap {
    my($srcfile, $dstfile) = @_;

    local ($_);
    local(*SRC,*DST);
    
    if (not defined $dstfile) {
	# Use File::Basename to separate the name and extension
	my ($name, $path, $ext) = fileparse($srcfile, qr/\.[^.]*/);

	# Construct the new filename (name + suffix + extension)
	$dstfile = $name . '_tag.htm';
    }
    
    open (SRC, $srcfile) or die "could not open $srcfile";
    open (DST, "> $dstfile") or die "could not open $dstfile";

    my $intbl = 0;
    my $inpath = 0;
    my $armtag = undef;
    my %allmap;

    my $dst;
	
    while (<SRC>) {
	
	/^(\d+\.\d+)\s+(\w+)/ && do {
	    my $num = $1;
	    my $nm = $2;
	    my $tag = lc $2;
	    $tag =~ s/\s+$//;
	    $tag =~ s/^\s+//;
	    $tag =~ s/\s+/-/;
	    $armtag = 'map-' . $tag;

	    push @{$dst}, "</td>\n</tr>\n" if $inpath;
	    push @{$dst}, "</table>\n" if $intbl;
	    
	    #print DST "</td>\n</tr>\n" if $inpath;
	    #print DST "</table>\n" if $intbl;
	    $inpath = 0; $intbl = 0;

	    die "duplicate definition for $nm" if exists $allmap{$tag};
	    $dst = [];
	    $allmap{$tag} = $dst;

	    
#	    print DST <<PERL_EOF;
	    push @{$dst}, <<PERL_EOF;



<!-- ============================== -->
<DIV><DIV class=quick>
<A HREF="clause4.htm#ao-$tag">AO</a>
<A HREF="annexG.htm#$tag">ARM</a>
</DIV>
<H4 ID="$armtag">$num $nm</H4>
</DIV>

<table class="map">
PERL_EOF
	    ;
	    $intbl = 1;
	    next; 
	};

	/^(\d+\.\d+.\d+)\s+(.+)/ && do {
	    my $num = $1;
	    my $nm = $2;
	    my $tag = lc $2;
	    $tag =~ /\(as\s+(\w+)\)/ and
	    	 $tag = $1;
	    $tag =~ s/\s+$//;
	    $tag =~ s/^\s+//;
	    $tag =~ s/\s+/-/;

	    push @{$dst}, "</td>\n</tr>\n" if $inpath;
	    push @{$dst}, "</table>\n" if $intbl;
	    
	    #print DST "</td>\n</tr>\n" if $inpath;
	    #print DST "</table>\n" if $intbl;
	    $inpath = 0; $intbl = 0;

#	    print DST <<PERL_EOF;
	    push @{$dst}, <<PERL_EOF;


<H5 ID="$armtag-$tag">$num $nm</H5>

<table class="map">
PERL_EOF
	    ;
	    $intbl = 1;
	    next; 
	};

	/^\s*AIM element/ && do {

	    /AIM element\s*:\s*(.*)/;
	    my $aim = $1;
	    $aim =~ s/\s+$//;
	    $aim =~ s/^\s+//;

	    if (not $aim) {
		warn "Bad aim element decl: $_";
		push @{$dst}, "BAD AIM\n";
		push @{$dst}, $_;
		#print DST "BAD AIM\n";
		#print DST $_;
	    }

	    push @{$dst}, "<tr><th>AIM element:</th>\n<td>$aim</td>\n</tr>\n\n";
	    # print DST "<tr><th>AIM element:</th>\n<td>$aim</td>\n</tr>\n\n";
	    next;
	};
	/^\s*Source/ && do {

	    /Source\s*:\s*(.*)/;
	    my $def = $1;
	    $def =~ s/\s+$//;
	    $def =~ s/^\s+//;

	    if (not $def) {
		warn "Bad source def: $_";
		push @{$dst}, "BAD SOURCE\n";
		push @{$dst}, $_;
		#print DST "BAD SOURCE\n";
		#print DST $_;
	    }

	    push @{$dst}, "<tr><th>Source:</th>\n<td>$def</td>\n</tr>\n\n";
	    #print DST "<tr><th>Source:</th>\n<td>$def</td>\n</tr>\n\n";
	    next;
	};
	/^\s*Reference path/ && do {
	    push @{$dst}, "<tr><th>Reference path:</th>\n<td class=\"path\">";
	    # print DST "<tr><th>Reference path:</th>\n<td class=\"path\">";
	    $inpath = 1;
	    next;
    
	};
	# else just copy

	s|>|&gt;|g;
	s|<|&lt;|g;
	push @{$dst}, $_;
	# print DST $_;
    }

    push @{$dst}, "</td>\n</tr>\n" if $inpath;
    push @{$dst}, "</table>\n" if $intbl;
	    
    #print DST "</td>\n</tr>\n" if $inpath;
    #print DST "</table>\n" if $intbl;

    foreach (sort keys %allmap) {
	print "MAP: $_\n";
	print DST @{$allmap{$_}};
    }
    
    close (DST);
    close (SRC);
}

sub main {
    foreach (@_) { tagmap($_); }
    return 1;
}

main (@ARGV);
