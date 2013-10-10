#!/usr/bin/perl -w
use strict;
use List::Util qw(first);

use Getopt::Long;

use Data::Dumper;

my $usage = "usage: flow-building.pl <argument> <value from> <value to> <step>\n";
my $prev = "test-prev.png";
my $next = "test-next.png";
my $xf = "./test_xaBuildFlow";
my $arg;
my $from;
my $to;
my $step;

my %args = (
    "pyr_scale"  => {'min' => 0,  'max' => 1,   'step' => 0.2},
    "levels"     => {'min' => 0,  'max' => 10,  'step' => 2},
    "winsize"    => {'min' => 10, 'max' => 300, 'step' => 5},
    "iterations" => {'min' => 1,  'max' => 10,  'step' => 1},
    "poly_n"     => {'min' => 5,  'max' => 10,  'step' => 2},
    "poly_sigma" => {'min' => 1,  'max' => 1.7, 'step' => 0.1},
    "flags"      => {'min' => 0,  'max' => 256, 'step' => 256}
);
my @def_vals = (
    "0.5",
    "1",
    "200",
    "3",
    "5",
    "1.1",
    "256",
);
my $debug = 0;


my $dir = $ENV{'PWD'};
my $recurse;

sub parse_i (@) {
    my $name = shift;
    my @a = split(/:/, $_[0]);
    die "nothing to parse" unless (@a);
#    my $name = shift @a || die "need at least one argument";
    die "couldn't find $name in my default args" unless ($args{$name});

    my $min  = shift @a || $args{$name}{'min'};
    my $max  = shift @a || $args{$name}{'max'};
    my $step = shift @a || $args{$name}{'step'};

    die "you can't have min ($min) > max ($max)" if ($min > $max);
    $args{$name} = {'min' => $min, 'max' => $max, 'step' => $step};
}

sub parse_a (@) {
    shift;
    my ($name, @a) = split (/:/, $_[0]);
    return parse_i($name, @_);
}

GetOptions (
    "dir|d=s"   => \$dir,
    "recurse|r" => \$recurse,
    "args|a=s"   => \&parse_a,
    "iterations=s" => \&parse_i,
    "flags=s"      => \&parse_i,
    "pyr_scale=s"  => \&parse_i,
    "levels=s"     => \&parse_i,
    "winsize=s"    => \&parse_i,
    "poly_n=s"     => \&parse_i,
    "poly_sigma=s" => \&parse_i,
    "gaussian|g"   => sub { $args{'flags'}{'min'} = 256;
                            $args{'winsize'} = {'min'  => '80',
                                                'max'  => '200',
                                                'step' => '20'};
    },
    )
    or die("Error in command line arguments\n");

# Helpers

die Dumper (\%args);

sub godo (@) {
    print @_;
    if (! $debug) {
        print `@_`;
    }
}


# Procedure

($arg, $from, $to, $step) = @ARGV; # Pick arguments

# No <argument> provided
if (! $arg) {
    print $usage;
    exit;
}


my $actual = $from;
while ($actual <= $to) {

#    godo("$xf $prev $next $fflow $args");
}
