 
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
my %tag_remap;

sub scandoc {
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
	/^<FIGURE><A NAME=\"([^\"]+)\"><\/A>/ && do {
	    my $tag = $1;
	    my $img = <SRC>;

	    my ($fn) = $img =~ /<IMG SRC=\"images\/([^\.]+).svg/i;
	    my $newtag = "fig-" . lc $fn;
	    
	    if ($tag eq $newtag or not $fn) {
		push @contents, $_;
		push @contents, $img;
		print "UNRECOGNIZED FIGURE $tag\n" if not $fn;
		next;
	    }

	    push @contents, "<FIGURE><A NAME=\"$newtag\"></A>\n";
	    push @contents, "<IMG SRC=\"images/$fn.svg\">\n";

	    $tag_remap{$tag} = $newtag;
	    $changed = 1;
	    

	    print "REMAP FIGURE $tag -- $newtag\n";
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



sub newlink {
    my($url) = @_;
    my ($tag) = $url =~ /#(.+)/;

    if (exists $tag_remap{$tag}) {
	my $oldurl = $url;
	$url =~ s/#(.+)/#$tag_remap{$tag}/;

	print "Change $oldurl to $url\n"
    }
    return $url;
}

sub fixlinks {
    my($file) = @_;

    my $bakfile = "$file~";
    my $changed = 0;
    my $tmp;
    my @contents;

    local ($_);
    local(*SRC);
    
    open (SRC, $file) or die "could not open $file";

    while (<SRC>) {
	$tmp = $_;
	s/href=\"([^\"]+)\"/"href=\"" . newlink($1) . "\""/eig;
	push @contents, $_;

	$changed = 1 if $tmp ne $_;
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

	/^-n$|^-scan$/ && do {
	    $do_scanonly=1;
	    shift; next;
	};

	/^-/ && die "$0: unknown option: $_ (use -help for usage)\n";

	push @files, glob $_;  # tack on as just a plain file
	shift;
    }

    foreach (@files) { scandoc ($_); }
    foreach (@files) { fixlinks ($_); }
    return 1;
}

main (@ARGV);

#
