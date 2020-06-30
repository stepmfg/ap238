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
# List ARM anchors for use in SVG generation

use strict;
my $do_scanonly=0;

sub gen_armidx {
    my($file, $dst) = @_;
    local ($_);
    local(*SRC);
    
    open (SRC, $file) or die "could not open $file";
    open (DST, "> $dst") or die "could not open $dst";
    
    print "Scanning $file\n";
    print DST "# AP238 ARM anchors\n";
    
    while (<SRC>) {
	/^<H3 ID=\"ao-([^\"]+)\">(.*)/i && do {
	    my $tag = $1;
	    my $body = $2;
	    $body =~ s/<\/H3>\s*$//i;
	    $body =~ s/^\s*((\d+|[A-Z])\.[\d\.]+)*\s+//;  

	    print DST "$body\tclause4.htm#ao-$tag\n";
	};
    }

    close (DST);
    close (SRC);
}


sub gen_aimidx {
    my($file, $dst) = @_;
    local ($_);
    local(*SRC);
    
    open (SRC, $file) or die "could not open $file";
    open (DST, "> $dst") or die "could not open $dst";
    
    print "Scanning $file\n";
    print DST "# AP238 AIM anchors\n";
    
    while (<SRC>) {
	/^<H5 ID=\"aim-([^\"]+)\">(.*)/i && do {
	    my $tag = $1;
	    my $body = $2;
	    $body =~ s/<\/H5>\s*$//i;
	    $body =~ s/^\s*((\d+|[A-Z])\.[\d\.]+)*\s+//;  

	    print DST "$body\tclause5.htm#aim-$tag\n";
	};
    }

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

    
    gen_armidx ("clause4.htm", "arm.link");
    gen_aimidx ("clause5.htm", "aim.link");
    return 1;
}


main (@ARGV);

