#!/usr/bin/env perl
use strict;
use warnings;

use lib 'lib';
use Schema;

my $db_file = '/home/gene/Data/ab-low-level.db';

my $schema = Schema->connect('dbi:SQLite:dbname=' . $db_file, '', '');

for my $i (1 .. 2) {
    my $artists = $schema->resultset('Artist')->count;
    my $recordings = $schema->resultset('Recording')->count;
    my $db_size = -s $db_file;

    print "Artists: $artists, Recordings: $recordings, DB_size: $db_size, Time: ", scalar(localtime), "\n";

    sleep 5 unless $i == 2;
}
