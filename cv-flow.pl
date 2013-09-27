#!/usr/bin/perl -w

use strict;

use Getopt::Long;
use File::Slurp; # libfile-slurp-perl
use Data::Dumper;

my $xf = './xaBuildFlow';
my $si = './slowmoInterpolate';
my $k  = 0;
my $skip = 0;
my $count = -1;
my $method = 'flow';

# optional behaviour
my $dir = '';
my $processed = 0;
my $args = "";
my $aglob = "*.png";
my $format = 'fixed-%06d.png';
my $fops = '';
my $fl;
my $debug;

GetOptions ("flowbuilder|xf|x=s"  => \$xf,
            "interpolator|si|i=s" => \$si,
            "first-frame|k=i"     => \$k,
            "frame-list|l=s"      => \$fl,
            "fops|fo|o=s"         => \$fops,
            "skip|s=i"            => \$skip,
            "count|c=i"           => \$count,
            "method|m=s"          => \$method,
#            "dir|d=s"             => \$dir,
            "debug|d"             => \$debug,
            "format|fmt|f=s"      => \$format,
            "args|a=s"            => \$args,
            "glob|g=s"            => \$aglob,
    )
    or die("Error in command line arguments\n");

my $d = "fixed-";
my $o = 0;

my @imgs = glob($aglob);
my ($glob) = $aglob =~ m/([^\*]+$)/;

sub godo (@) {
    print @_;
    if (! $debug) {
        print `@_`;
    }
}

my @frames;
if ($fl) {
    @frames = read_file($fl);
#    print Dumper (@frames);
}

$format = "fixed-%06d$glob";

sub img_add ($$$ ) {
    my ($h, $n, $o) = @_;
    return sprintf ("$h%0".length($n)."d".$glob, $n + $o);
}

#print "glob: $glob, imgs: @imgs\n";
foreach (@imgs) {
    if ($skip-- > 0) {
        print "skipping frame $_\n";
        next;
    }

    my ($h, $n) = $_ =~ m/^([^\d]+)(\d+)$glob/ or next;
    my $next = img_add ($h, $n, 1);

    my $recf = sprintf ($format, $processed + $o);
    my $nexf = sprintf ($format, $processed + $o + 1);


    if (@frames) {
        if ($frames[0] > $n) {
            print "got frame-list, skipping frame $_\n";
            next;
        } elsif ($frames[0] == $n) {
            shift @frames;
        } else {
            die "something went wrong, got $frames[0] <  and $n\n";
        }
    }

    printf "%08d/$count: $_ -> $recf\n", $processed;
    godo ("cp $_ $recf");

    unless (($n+$k)%5) {
        print "adding frame between: $_ and $next, to $nexf\n";

        if ($method eq 'flow') {
            my $fflow = "flow-fwd-".($n)."-".($n+1).".sVflow";
            my $bflow = "flow-bkw-".($n+1)."-".($n).".sVflow";
            print "flow from $_ to $next\n";
            godo ("$xf $_ $next $fflow $fops");
            print "flow from $next to $_\n";
            godo ("$xf $next $_ $bflow");
            print "twoway interpolation\n";
            godo ("$si twoway $_ $next $fflow $bflow .out%1$glob 0 2");
            print "saving center interpolation\n";
            godo ("mv .out00000001$glob $nexf");
            godo ("rm -rf .out*");
        } elsif ($method eq 'biflow') {
            my $fflow = "flow";
            my $bflow = "rflow";
            print "biflow from $_ to $next\n";
            print "$xf $_ $next $args\n";
            godo ("$xf $_ $next $args");
            print "twoway interpolation\n";
            godo ("$si twoway $_ $next $fflow $bflow .out%1$glob 0 2");
            print "saving center interpolation\n";
            godo ("mv .out00000001$glob $nexf");
            godo ("rm -rf .out*");
        } elsif ($method eq 'flowforward') {
            my $fflow = "flow-fwd-".($n)."-".($n+1).".sVflow";
            print "flow from $_ to $next\n";
            godo ("$xf $_ $next $fflow");
            print "oneway interpolation\n";
            godo ("$si forward $_ $fflow .out%1$glob 0 2");
            print "saving center interpolation\n";
            godo ("mv .out00000001$glob $nexf");
            godo ("rm -rf .out*");

        } elsif ($method eq 'average') {
            print "rendering average between $_ and $next\n";
            godo ("convert $_ $next -average -flatten $nexf");
        } elsif ($method eq 'debug') {
            print "debug, skipping conversion\n";
        }

        $o++;
    }

    die "reached my count" if ($processed++ == $count);
}
