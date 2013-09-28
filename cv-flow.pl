#!/usr/bin/perl -w

use strict;

use Getopt::Long;
use File::Slurp; # libfile-slurp-perl
use File::Temp qw/tempdir/;

my $tmp = tempdir (CLEANUP => 1);

use Data::Dumper;

my $xf = './xaBuildFlow';
my $si = './slowmoInterpolate';
my $bf = './biflow.pl';
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
my $follow = 0;
my $fl;
my $debug;

GetOptions ("flowbuilder|xf|x=s"  => \$xf,
            "interpolator|si|i=s" => \$si,
            "biflow|bf|b=s"       => \$bf,
            "first-frame|k=i"     => \$k,
            "frame-list|l=s"      => \$fl,
            "skip|s=i"            => \$skip,
            "count|c=i"           => \$count,
            "method|m=s"          => \$method,
#            "dir|d=s"             => \$dir,
            "debug|d"             => \$debug,
            "format|fmt|f=s"      => \$format,
            "args|a=s"            => \$args,
            "glob|g=s"            => \$aglob,
            "follow-links|w"      => \$follow,
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
    @frames = read_file($fl, chomp => 1);
#    print Dumper (@frames);
}

#$format = $format || "fixed-%06d$glob";

sub img_add ($$$ ) {
    my ($h, $n, $o) = @_;
    return sprintf ("$h%0".length($n)."d".$glob, $n + $o);
}

sub parse_img ($$ ) {
    my ($img, $glob) = @_;
    return $img =~ m/^(.+[^\d])(\d+)$glob/ or die "can't parse image: $img, $glob";
}

#print "glob: $glob, imgs: @imgs\n";
foreach (@imgs) {
    if ($skip-- > 0) {
        print "skipping frame $_\n";
        next;
    }

    my ($h, $n) = parse_img ($_, $glob);
    my $next = img_add ($h, $n, 1);

    my $recf = sprintf ($format, $processed + $o);
    my $nexf = sprintf ($format, $processed + $o + 1);

    my $act = 0;
    if (@frames) {
        my $img = $_;
        if ($follow) {
            $img = readlink || $_;
        }

        my ($H, $N) = parse_img ($img, $glob);
        print "\n==$n:$N==";
        while ($frames[0] < $N) {
            print "skipping $frames[0], we're far ahead\n";
            shift @frames;
        }
        if ($frames[0] > $N) {
            print "WARNING got a big gap: ".($frames[0] - $N)." !\n" if ($frames[0] - 5 > $N);
            print "got frame-list, skipping frame $_ -> $img, next: '$frames[0]'\n";
        } elsif ($frames[0] == $N) {
            shift @frames;
            print "processing\n";
            $act++;
        } else {
            die "something went wrong, got $frames[0] <  and $N\n";
        }
    } else {
        $act = (!($n+$k)%5);
    }

    printf "%08d/$count: $_ -> $recf\n", $processed;
    godo ("ln -sf $_ $recf");

    if ($act) {
        print "adding frame between: $_ and $next, to $nexf\n";

        if ($method eq 'flow' or $method eq 'a') {
            my $fflow = "flow-fwd-".($n)."-".($n+1).".sVflow";
            my $bflow = "flow-bkw-".($n+1)."-".($n).".sVflow";
            print "flow from $_ to $next\n";
            godo ("$xf $_ $next $fflow $args");
            print "flow from $next to $_\n";
            godo ("$xf $next $_ $bflow");
            print "twoway interpolation\n";
            godo ("$si twoway $_ $next $fflow $bflow $tmp/out%1$glob 0 0");
            print "saving center interpolation\n";
            godo ("mv $tmp/out0000000$glob $nexf");
            godo ("rm -rf $tmp/*");
        } elsif ($method eq 'biflow' or $method eq 'b') {
            my $fflow = "flow";
            my $bflow = "rflow";
            print "biflow from $_ to $next\n";
            godo ("$bf $xf $_ $next $args");
            print "twoway interpolation\n";
            godo ("$si twoway $_ $next $fflow $bflow $tmp/%1$glob 0 0");
            print "saving center interpolation\n";
            godo ("mv $tmp/00000000$glob $nexf");
            godo ("rm -rf $tmp/*");
        } elsif ($method eq 'flowforward' or $method eq 'c') {
            my $fflow = "flow-fwd-".($n)."-".($n+1).".sVflow";
            print "flow from $_ to $next\n";
            godo ("$xf $_ $next $fflow $args");
            print "oneway interpolation\n";
            godo ("$si forward $_ $fflow $tmp/%1$glob 0 0");
            print "saving center interpolation\n";
            godo ("mv $tmp/00000000$glob $nexf");
            godo ("rm -rf $tmp/*");
        } elsif ($method eq 'average') {
            print "rendering average between $_ and $next\n";
            godo ("convert $_ $next -average -flatten $nexf");
        } elsif ($method eq 'debug') {
            print "debug, skipping conversion\n";
        } else {
            die "method no supported: $method";
        }

        $o++;
    }

    die "reached my count" if ($processed++ == $count);
}
