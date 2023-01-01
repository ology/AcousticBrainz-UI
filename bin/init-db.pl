#!/usr/bin/env perl
use strict;
use warnings;

use lib 'lib';
use Schema;

my $db_file = $ENV{HOME} . '/Data/ab-low-level.db';

unlink $db_file
    if -e $db_file;
unlink $db_file . '.journal'
    if -e $db_file . '.journal';

my $schema = Schema->connect('dbi:SQLite:dbname=' . $db_file, '', '');

$schema->deploy({ add_drop_table => 1 });
