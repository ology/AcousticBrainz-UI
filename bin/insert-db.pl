#!/usr/bin/env perl
use strict;
use warnings;

use File::Find::Rule;
use File::Slurper 'read_text';
use JSON::MaybeXS;

use Schema;

my $base = '/home/guest/tmp/acousticbrainz/';

my $path = shift || $base . 'acousticbrainz-lowlevel-json-20150129/lowlevel';

print "Gathering files...\n";
my @files = File::Find::Rule->file()->name('*.json')->in($path);

my $schema = Schema->connect('dbi:SQLite:dbname=/home/gene/Data/ab-low-level.db', '', '');

my %name_ids;

print "Parsing JSON...\n";
my $i = 0;
for my $file (@files) {
    my $content = read_text($file);
    my $raw = decode_json($content);

    my $artist_name = $raw->{metadata}{tags}{artist}[0] || $raw->{metadata}{tags}{albumartist}[0];
    next unless $artist_name;

    unless ($name_ids{$artist_name}) {
        my $artist_mbid = $raw->{metadata}{tags}{musicbrainz_artistid}[0];
        my $artist = $schema->resultset('Artist')->create({ name => $artist_name, mbid => $artist_mbid });
        $name_ids{$artist_name} = $artist->id;
    }
    my $artist_id = $name_ids{$artist_name};

    $i++;
    warn("\t$i. $artist_name ($artist_id)\n");

    $file =~ s|^$base||;

    $schema->resultset('Recording')->create({ artist_id => $artist_id, file => $file });
}
