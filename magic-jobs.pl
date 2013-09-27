#! perl -w
use strict;
use Time::HiRes qw[ sleep ];
use threads;
use threads::shared;
use Sys::CPU; # libsys-cpu-perl
use Getopt::Long;

use Data::Dumper;

my $njob = Sys::CPU::cpu_count();
my @cmds;

print "will spawn: $njob cmds.\n";

my $dir = $ENV{'PWD'};
my $recurse;

GetOptions (
    "dir|d=s"   => \$dir,
    "recurse|r" => \$recurse,
    "cmd|c=s"   => sub { push @cmds, $_[1]},
    "jobs|j=i"  => \$njob,
    )
    or die("Error in command line arguments\n");

if ($recurse) {
    opendir my $dh, $dir
        or die "$0: opendir: $!";
    my @dirs = grep {-d "$dir/$_" && ! /^\.{1,2}$/} readdir($dh);

    my @rcmds;
    foreach my $d (@dirs) {
        foreach (@cmds) {
            push @rcmds, "cd $dir/$d && $_";
        }
    }

    @cmds = @rcmds;
}

#die Dumper (\@cmds);

my $running :shared = 0;
my $done :shared = 0;
for my $cmd ( @cmds ) {
    async{
        ++$running;
        system $cmd;
        --$running;
        ++$done;
    }->detach;
    printf( "\rdone:$done,\trunning: $running" ), sleep 0.1
        while $running > $njob;
}
