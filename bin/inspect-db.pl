#!/usr/bin/env perl
use strict;
use warnings;

use lib 'lib';
use Schema;

my $db_file = '/home/gene/Data/ab-low-level.db';

my $schema = Schema->connect('dbi:SQLite:dbname=' . $db_file, '', '');

my $artists = $schema->resultset('Artist')->count;
my $recordings = $schema->resultset('Recording')->count;
my $db_size = -s $db_file;

return "{ artists => $artists, recordings => $recordings, db_size => $db_size }\n";
