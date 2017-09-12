#!/usr/local/bin/perl
# 
# Copyright (c) 1991-2017 by STEP Tools Inc.
# All Rights Reserved
# 
# This software is furnished under a license and may be used and
# copied only in accordance with the terms of such license and with
# the inclusion of the above copyright notice.  This software and
# accompanying written materials or any other copies thereof may
# not be provided or otherwise made available to any other person.
# No title to or ownership of the software is hereby transferred.
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
    my @num;

    local ($_);
    local(*SRC);
    
    open (SRC, $file) or die "could not open $file";

    while (<SRC>) {
	/^<H2 CLASS=\"clause\"><A NAME=\"clause-(\d+)\"><\/A>(.*)/ && do {
	    @num = ($1);
	    my $body = $2;
	    my $tag = (join '-', @num);
	    my $sec = (join '.', @num);

	    $body =~ s/\s*[\d\.]+\s+//;
	    $_ = "<H2 CLASS=\"clause\"><A NAME=\"clause-" . $tag . "\"></A>" .  
		$sec . " " . $body . "\n";
	};

	/^<H3><A NAME=\"clause-([\d-]+)\"><\/A>(.*)/ && do {
	    my $body = $2;
	    my @newnum = split /-/, $1;
	    my $oldtag = $1;

	    if ((scalar @num) > (scalar @newnum)) {
		splice @num, (scalar @newnum);  # shrink
	    }

	    while ((scalar @num) < (scalar @newnum)) {
		push @num, 0;  # grow
	    }

	    my $cnt = pop @num;
	    push @num, $cnt+1;

	    my $tag = (join '-', @num);
	    my $sec = (join '.', @num);
	    
	    $body =~ s/\s*[\d\.]+\s+//;
	    $_ = "<H3><A NAME=\"clause-" . $tag . "\"></A>" . 
		$sec . " " . $body . "\n";

	    if ($tag ne $oldtag) {
		print "Changed: $oldtag  --> $tag\n";
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
	unlink $bakfile		or die ("$bakfile: $!");
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
