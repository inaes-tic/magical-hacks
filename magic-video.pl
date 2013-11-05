#! perl -w
use strict;

use Getopt::Long qw(:config no_ignore_case);
use Data::Dumper;

my $files_dir = 'magic-video-files/';

our $opt_dir     = $ENV{'PWD'};
our $opt_out     = 120;
our $opt_profile = 'atsc_1080p_25'; # atsc_720p_25
our $opt_melt    = 'melt';
our $opt_input;
our $opt_audio   = $opt_dir . '/' . $files_dir . 'audio.mp3';
our $opt_frames;

my @inlogos;
my @outlogos;
my @intitles;
my @outtitles;

GetOptions (
    "dir|d=s",
    "out|o=i",
    "melt|m=s",
    "profile|p=s",
    "input|i=s",
    "audio|a=s",
    "frames|f=i",
    "intitle|t=s" => sub { push @intitles,  $_[1]},
    "outtitle|T=s"=> sub { push @outtitles, $_[1]},
    "inlogo|l=s"  => sub { push @inlogos,   $_[1]},
    "outlogo|L=s" => sub { push @outlogos,  $_[1]},
    )
    or die("Error in command line arguments\n");

die "Need at least one input file (-i)" unless ($opt_input);
my $output = shift;

@intitles  = ("MBC-Playout")                unless (@intitles);
@outtitles = ("Join us at www.opcode.coop") unless (@outtitles);
@inlogos   = (
    $files_dir . "logo_inaes.png:colour=white",
    $files_dir . "logo_mbc_playout.png",
    $files_dir . "logo_opcode.png"
    ) unless (@inlogos);
@outlogos  = (
    $files_dir . "logo_opcode.png",
    $files_dir . "logo_mbc_playout.png",
    $files_dir . "logo_inaes.png:colour=white"
    ) unless (@outlogos);

print Dumper(\@intitles, \@outtitles, \@inlogos, \@outlogos);

my $mix = "
    -mix 25 -mixer luma ";
my $mixc = 0;

sub mlt_do ($$) {
    my $func = shift;

    my ($ret, $out) = &$func (@_);
    if ($mixc++) {
        $ret .= $mix;
    }
    return $ret;
}

sub parse_opts ($% ) {
    my $arg  = shift;
    my $args = shift;

    return map { $arg =~ m/:$_=([^:]+)/ ?($_ => $1):($_ => $$args{$_})} keys (%$args);
}

sub add_logo ($ ) {

    my ($logo) = m/^([^:]+)/ or die "need logo";

    my %args = parse_opts ($_,
                           {'out'    => $opt_out,
                            'colour' => 'black'});

    return ("
    colour:$args{colour}
            out=$args{out}
            -attach watermark:$opt_dir/$logo
            composite.valign=c
            composite.halign=c", $args{'out'});
}

sub add_title ($ ) {
    my ($text) = m/^([^:]+)/ or die "need text";

    my %args = parse_opts ($_,
                           {'out'      => $opt_out,
                            'fgcolour' => 'white',
                            'bgcolour' => 'black',
                            'align'    => 'center',
                            'pad'      => '100',
                            'family'   => 'Courier',
                            'size'     => '48',
                            'weight'   => '500'});

    return ("
    pango
        text=\"$text\"
        out=$args{out}
        fgcolour=$args{fgcolour}
        bgcolour=$args{bgcolour}
        align=$args{align}
        pad=$args{pad}
        family=$args{family}
        size=$args{size}
        weight=$args{weight} ", $args{'out'});
}

my $cmd = $opt_melt;

$cmd .= "
    -profile $opt_profile ";

foreach (@inlogos) {
    m/\S/ and $cmd .= mlt_do (\&add_logo,  $_);
}

foreach (@intitles) {
    m/\S/ and $cmd .= mlt_do (\&add_title, $_);
}

$cmd .= "
    $opt_input";
$cmd .= $mix;

foreach (@outtitles) {
    m/\S/ and $cmd .= mlt_do (\&add_title, $_);
}

foreach (@outlogos) {
    m/\S/ and $cmd .= mlt_do (\&add_logo,  $_);
}

if ($opt_audio and $opt_frames) {
    $cmd .= "
    -track avformat:$opt_audio \
        video_index=-1 \
        in=0 \
        out=$opt_frames ";
}

if ($output) {
    $cmd .= "
    -consumer avformat:$output \
        acodec=aac \
        vcodec=libx264";
}

print "==> '$cmd'\n";

$cmd =~ s/\n/ /g;
system($cmd);
