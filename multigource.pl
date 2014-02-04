#!/usr/bin/perl -w

use strict;
use Data::Dumper;

# if this doesn't return:
# git log --pretty=format:user:%aN%n%ct --reverse --raw --encoding=UTF-8 --no-renames
# everything will fail.

my $logc = `gource --log-command git`;

sub git_slurp ($ ) {
    my $dir = shift;
    my %ret;

    open (my $FH, "cd $dir; $logc |");
    $dir =~ s/^.\///;

    local $/ = "user:";
    while (<$FH>) {
        chomp;
        $_ eq "" and next;
        $_ = 'user:'.$_;

        s/(\.\.\. [MDA]\s)/$1$dir\//g;

        my ($time) = m/\n(\d+)/;
        $ret{$time} = $_;
    }
    return \%ret;
}

my %commits;
my @dirs = map {s,/.git,,g; $_ } split ('\n', `find . -name '.git' -type d`);

foreach (@dirs) {
    my $h = git_slurp($_);
    @commits {keys %$h} = values %$h;
}

foreach (sort (keys %commits)) {
    print $commits{$_};
};


