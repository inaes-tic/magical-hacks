#!/usr/bin/perl -w
use strict;
use List::Util qw(first);

my $usage = "usage: flow-building.pl <argument> <value from> <value to> <step>\n";
my $prev = "test-prev.png";
my $next = "test-next.png";
my $xf = "./test_xaBuildFlow";
my $arg;
my $from;
my $to;
my $step;
my @args = (
    "pyr_scale",
    "levels",
    "winsize",
    "iterations",
    "poly_n",
    "poly_sigma",
    "flags"
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

# Helpers

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

my $id = first { $args[$_] eq $arg } 0..$#args; # Get <argument> index

# Only <argument> available
if (! $from) {
    print "Default value for $arg is $def_vals[$id]\n";
}

my $actual = $from;
while ($actual <= $to) {

    godo("$xf $prev $next $fflow $args");
}
