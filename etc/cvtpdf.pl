
my @files;
foreach (@ARGV) {
    push @files, glob $_;
}

my $ink = "\"c:/Program Files/Inkscape/inkscape.exe\"";
foreach (@files) {
    my $f = $_;
    my $svg = $_;
    $svg =~ s/\.[^\.]+/.svg/;

    my $cmd = "$ink $f --export-plain-svg=$svg";
    print $cmd, "\n";
    system($cmd);
}


