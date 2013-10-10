#!/usr/bin/perl -w
use strict;

my $usage = "usage: guess-frame.pl <scene_number> [ <image_number> ... ]\n";
my $sc_prefix = "scene";
my $sc_num_len = 4;
my $fixed_num_len = 6;
my $scene;
my $frame;


# Helpers

sub zero($$) {
    my ($val, $cant) = @_;
    while (length($val) < $cant) {
        $val = "0".$val;
    }
    return $val;
}


# Procedure

$scene = shift(@ARGV);

if (!$scene) {
    print $usage;
    exit;
}

my $dir = $sc_prefix.zero($scene, $sc_num_len)."/";

foreach (@ARGV) {
    my $file = $dir."fixed-".zero($_, $fixed_num_len)."a.png";
    if (! -l $file) {
        print "$file is not a link!\n";
    } else {
        while(-l $file) {
            $file = $dir.readlink($file);
        }
        ($frame) = $file =~ m/^$dir[^\d]+([\d]+)[^\d]+$/;
        $frame = int($frame) + 1; # Convert to Santiago's index (starting by 1)
        print "$frame\n";
    }
}
