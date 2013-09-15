#!/usr/bin/perl -w
use strict;

my $buildflow = shift;
my $i1 = shift;
my $i2 = shift;

print `$buildflow $i1 $i2 flow  @ARGV`;
print `$buildflow $i2 $i1 rflow @ARGV`;

