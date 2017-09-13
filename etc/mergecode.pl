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

use strict;

my $do_scanonly=0;

#----------------------------------------
# finds the bug number and tags the file if it does not have one
#
sub mergecode {
    my($file) = @_;

    my $bakfile = "$file~";
    my $changed = 0;
    my $inblock = 0;
    my @contents;
    my @num;

    local ($_);
    local(*SRC);
    
    open (SRC, $file) or die "could not open $file";

    while (<SRC>) {
      restart:
	/<P CLASS=\"example-mono\">/ && do {
	    if (!$inblock) {
		$inblock = 1;
		push @contents, "<PRE CLASS=\"example\">\n";
	    }
	    $_ = <SRC>;

	    s/<\/P>$//;
	    push @contents, $_;
	    $changed = 1;
	    next;
	};

	push @contents, "</PRE>\n" if $inblock;
	
	$inblock = 0;
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
	mergecode ($_);
    }
    return 1;
}

main (@ARGV);

#
