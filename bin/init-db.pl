#!/usr/bin/env perl
use strict;
use warnings;

use lib 'lib';
use Schema;

my $schema = Schema->connect('dbi:SQLite:dbname=/home/gene/Data/ab-low-level.db','','');

$schema->deploy({ add_drop_table => 1 });
