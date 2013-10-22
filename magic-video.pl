#! perl -w
use strict;

use Getopt::Long qw(:config no_ignore_case);
use Data::Dumper;

our $opt_dir     = $ENV{'PWD'};
our $opt_out     = 120;
our $opt_profile = 'dv_pal_wide';
our $opt_melt    = 'melt';
our $opt_input   = 'demo.mpg';
our $opt_ffmpeg  = 'ffmpeg';

my @inlogos;
my @outlogos;
my @intitles;
my @outtitles;

GetOptions (
    "dir|d=s",
    "out|o=i",
    "intitle|t=s" => sub { push @intitles,  $_[1]},
    "outtitle|T=s"=> sub { push @outtitles, $_[1]},
    "inlogo|l=s"  => sub { push @inlogos,   $_[1]},
    "outlogo|L=s" => sub { push @outlogos,  $_[1]},
    "melt|m=s",
    "profile|p=s",
    "ffmpeg|f=s",
    "input|i=s",
    )
    or die("Error in command line arguments\n");

@intitles  = ("MBC-Playout")                unless (@intitles);
@outtitles = ("Join us at www.opcode.coop") unless (@outtitles);
@inlogos   = ("logo_inaes.jpg:white", "mbc_playout.png", "logo_coop.png") unless (@inlogos);
@outlogos  = ("logo_coop.png", "mbc_playout.png", "logo_inaes.jpg:white") unless (@outlogos);

print Dumper(\@intitles, \@outtitles, \@inlogos, \@outlogos);

my ($frames) = `$opt_melt $opt_input -consumer xml` =~ m,name\s*=\s*"?length"?\s*>\s*(\d+)\s*<, or die "Couldn't parse XML: $opt_input";

my $mix = "
    -mix 25 -mixer luma ";
my $mixc = 0;

sub mlt_do ($$) {
    my $func = shift;

    my ($ret, $out) = &$func (@_);
    if ($mixc++ > 1) {
        $ret .= $mix;
    }
    $frames += $out;
    return $ret;
}

sub add_logo ($ ) {
    my ($logo, $colour) = m/(^[^:]+):?(.*)/ || die "need a logo";

    $colour = 'black' unless ($colour);

    return ("
    colour:$colour
            out=$out
            -attach watermark:$opt_dir/$logo
            composite.valign=c
            composite.halign=c", $out);
}

sub add_title ($ ) {
    my ($text) = m/^([^:]+)/;
    die "need text" unless ($text);

    my ($fgcolour) = m/:fgcolour=([^:]+)/ || ('white');
    my ($bgcolour) = m/:bgcolour=([^:]+)/ || ('black');
    my ($align)    = m/:align=([^:]+)/    || ('center');
    my ($pad)      = m/:pad=([^:]+)/      || ('100');
    my ($family)   = m/:family=([^:]+)/   || ('Courier');
    my ($size)     = m/:size=([^:]+)/     || ('48');
    my ($weight)   = m/:weight=([^:]+)/   || ('500');

    return ("
    pango
        text=\"$text\"
        out=$out
        fgcolour=$fgcolour
        bgcolour=$bgcolour
        align=$align
        pad=$pad
        family=$family
        size=$size
        weight=$weight ", $out);
}

my $cmd = $opt_melt;

$cmd .= "
    -profile $opt_profile ";

foreach (@inlogos) {
    $cmd .= mlt_do (\&add_logo, $_);
}

foreach (@intitles) {
    $cmd .= mlt_do (\&add_title, $_);
}

$cmd .= "
    $opt_input";
$cmd .= $mix;

foreach (@outlogos) {
    $cmd .= mlt_do (\&add_logo, $_);
}

foreach (@outtitles) {
    $cmd .= mlt_do (\&add_title, $_);
}

$cmd .= "
    -track avformat:$opt_dir/audio2.mp3 \
        video_index=-1 \
        in=0 \
        out=$frames ";

$cmd .= "
    -consumer avformat:$opt_dir/out.mp4 \
        acodec=aac \
        vcodec=libx264";

print "==> '$cmd'\n";

$cmd =~ s/\n/ /g;
system($cmd);