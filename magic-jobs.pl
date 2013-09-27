#! perl -w
use strict;
use Time::HiRes qw[ sleep ];
use threads;
use threads::shared;
use Sys::CPU; # libsys-cpu-perl
use Getopt::Long;

use Data::Dumper;

my $njob = Sys::CPU::cpu_count();
my @jobs;

print "will spawn: $njob jobs.\n";

my $dir = $ENV{'PWD'};
my $recurse;

GetOptions (
    "dir|d=s"   => \$dir,
    "recurse|r" => \$recurse,
    "job|j=s"   => sub { push @jobs, $_[1]},
    )
    or die("Error in command line arguments\n");

if ($recurse) {
    opendir my $dh, $dir
        or die "$0: opendir: $!";
    my @dirs = grep {-d "$dir/$_" && ! /^\.{1,2}$/} readdir($dh);

    my @rjobs;
    foreach my $d (@dirs) {
        foreach (@jobs) {
            push @rjobs, "cd $dir/$d && $_";
        }
    }

    @jobs = @rjobs;
}

#die Dumper (\@jobs);

my $running :shared = 0;
my $done :shared = 0;
for my $cmd ( @jobs ) {
    async{
        ++$running;
        system $cmd;
        --$running;
        ++$done;
    }->detach;
    printf( "\rdone:$done,\trunning: $running" ), sleep 0.1
        while $running > $njob;
}
