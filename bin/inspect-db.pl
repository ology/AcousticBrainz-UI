#!/usr/bin/env perl
use strict;
use warnings;

use Number::Format;

use lib 'lib';
use Schema;

my $db_file = $ENV{HOME} . '/Data/ab-low-level.db';

my $schema = Schema->connect('dbi:SQLite:dbname=' . $db_file, '', '');

my $nf = Number::Format->new;

for my $i (1 .. 2) {
    my $artists = $schema->resultset('Artist')->count;
    my $recordings = $schema->resultset('Recording')->count;
    my $db_size = -s $db_file;

    printf "Artists: %s; Recordings: %s; DB size: %s; Time: %s\n",
        $nf->format_number($artists),
        $nf->format_number($recordings),
        $nf->format_number($db_size),
        scalar(localtime);

    sleep 5 unless $i == 2;
}
