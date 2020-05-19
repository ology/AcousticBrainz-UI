#!/usr/bin/env perl
use strict;
use warnings;

use Schema;

my $schema = Schema->connect('dbi:SQLite:dbname=ab-low-level.db','','');

$schema->deploy({ add_drop_table => 1 });
