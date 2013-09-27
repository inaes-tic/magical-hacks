#! perl -w

use strict;

use List::MoreUtils qw(uniq);
use Data::Dumper;

my $dir='niggah';

my @files = glob ("fixed*.png");

my @links = grep {  -l "./$_"} @files;
my @procs = grep {! -l "./$_"} @files;

@links = uniq map {s/[^\d](.png)/$1/; $_} @links;

`mkdir -p $dir`;

foreach (@links) {
    my $o = $_;
    $o =~ s/.png/a.png/;
    system "cp $o $dir/$_";
}

foreach (@procs) {
    system "cp $_ $dir/$_";
}

