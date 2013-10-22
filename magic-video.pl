#! perl -w
use strict;

use Getopt::Long qw(:config no_ignore_case);
use Data::Dumper;


my $basedir = $ENV{'PWD'};
my $out=120;
my @inlogos;
my @outlogos;
my @intitles;
my @outtitles;
my $profile = 'dv_pal_wide';
my $cmd = 'melt';
my $video = 'demo.mpg';

GetOptions (
    "dir|d=s"     => \$basedir,
    "out|o=i"     => \$out,
    "intitle|t=s" => sub { push @intitles, $_[1]},
    "outtitle|T=s"=> sub { push @outtitles, $_[1]},
    "inlogo|l=s"  => sub { push @inlogos, $_[1]},
    "outlogo|L=s" => sub { push @outlogos, $_[1]},
    "melt|m=s"    => \$cmd,
    "profile|p=s" => \$profile,
    )
    or die("Error in command line arguments\n");

@intitles  = ("MBC-Playout")                unless (@intitles);
@outtitles = ("Join us at www.opcode.coop") unless (@outtitles);
@inlogos   = ("logo_inaes.jpg:white", "mbc_playout.png", "logo_coop.png") unless (@inlogos);
@outlogos  = ("logo_coop.png", "mbc_playout.png", "logo_inaes.jpg:white") unless (@outlogos);

print Dumper(\@intitles, \@outtitles, \@inlogos, \@outlogos);

my $mix = "
    -mix 25 -mixer luma ";

sub add_logo ($ ) {
    my ($logo, $colour) = m/(^[^:]+):?(.*)/ || die "need a logo";

    $colour = 'black' unless ($colour);

    return "
    colour:$colour
            out=$out
            -attach watermark:$basedir$logo
            composite.valign=c
            composite.halign=c";
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

    return "
    pango
        text=\"$text\"
        out=$out
        fgcolour=$fgcolour
        bgcolour=$bgcolour
        align=$align
        pad=$pad
        family=$family
        size=$size
        weight=$weight "
}

$cmd .= "
    -profile $profile ";

foreach (@inlogos) {
    $cmd .= add_logo ($_);
    $cmd .= $mix;
}

foreach (@intitles) {
    $cmd .= add_title ($_);
    $cmd .= $mix;
}

$cmd .= "
    $video";
$cmd .= $mix;

foreach (@outlogos) {
    $cmd .= add_logo ($_);
    $cmd .= $mix;
}

foreach (@outtitles) {
    $cmd .= add_title ($_);
    $cmd .= $mix;
}

$cmd .= "
    -track avformat:$basedir/audio2.mp3 \
        video_index=-1 \
        in=0 \
        out=3453 ";

$cmd .= "
    -consumer avformat:$basedir/out.mp4 \
        acodec=aac \
        vcodec=libx264";

print "==> '$cmd'\n";

$cmd =~ s/\n/ /g;
system($cmd);