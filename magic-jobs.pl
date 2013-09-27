#! perl -slw
use strict;
use Time::HiRes qw[ sleep ];
use threads;
use threads::shared;
use Sys::CPU; # libsys-cpu-perl

use Data::Dumper;

my $njob = Sys::CPU::cpu_count();
my @jobs;

print "will spawn: $njob jobs.\n";

my $root = $ENV{'PWD'};
opendir my $dh, $root
  or die "$0: opendir: $!";
my @dirs = grep {-d "$root/$_" && ! /^\.{1,2}$/} readdir($dh);

foreach (@dirs) {
push @jobs, (
qq[ cd $_ && ~/src/TV/CN23/magical-hacks/cv-flow.pl -l ../frames-resched.txt \
 	-b '~/src/TV/CN23/biflow.pl' -x '~/src/TV/CN23/xaBuildFlow' \
 	-i ~/src/TV/CN23/slowmoInterpolate \
 	-m c -g 'scene*.png' -w -f "fixed-%06da.png"],
qq[ cd $_ && ~/src/TV/CN23/magical-hacks/cv-flow.pl -l ../frames-resched.txt \
        -b '~/src/TV/CN23/biflow.pl' -x '~/src/TV/CN23/xaBuildFlow' \
        -i ~/src/TV/CN23/slowmoInterpolate \
        -m b -g 'scene*.png' -w -f "fixed-%06db.png"],
qq[ cd $_ && ~/src/TV/CN23/magical-hacks/cv-flow.pl -l ../frames-resched.txt \
        -b '~/src/TV/CN23/biflow.pl' -x '~/src/TV/CN23/xaBuildFlow' \
        -i ~/src/TV/CN23/slowmoInterpolate \
        -a '0.5 3 200 3 5 1.3 256' \
        -m b -g 'scene*.png' -w -f "fixed-%06dc.png"],
qq[ cd $_ && ~/src/TV/CN23/magical-hacks/cv-flow.pl -l ../frames-resched.txt \
        -b '~/src/TV/CN23/biflow.pl' -x '~/src/TV/CN23/xaBuildFlow' \
        -i ~/src/TV/CN23/slowmoInterpolate \
        -a '0.5 3 200 3 5 1.3 256' \
        -m c -g 'scene*.png' -w -f "fixed-%06dd.png"]
);
}

die Dumper (\@jobs);

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
