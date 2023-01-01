#!/usr/bin/env perl
use strict;
use warnings;

use File::Find::Rule;
use File::Slurper 'read_text';
use JSON::MaybeXS;
use Storable;

use lib 'lib';
use Schema;

my $path = shift || die "Usage: perl $0 /feature-extraction/some-tune.json\n";

my $db_file = 'abui.db';

print "Gathering files...\n";
my $files;
my $files_dat = 'ab-files.dat';
if (-e $files_dat) {
    $files = retrieve $files_dat;
}
else {
    $files = [ File::Find::Rule->file()->name('*.json')->in($path) ];
    store $files, $files_dat;
}

my $schema = Schema->connect("dbi:SQLite:dbname=$db_file", '', '');

my %name_ids;

print "Parsing JSON...\n";
#my $i = 0;
for my $file (@$files) {
    my $content = read_text($file);
    my $raw = decode_json($content);

    my $artist_name = $raw->{metadata}{tags}{artist}[0] || $raw->{metadata}{tags}{albumartist}[0];
    next unless $artist_name;

    unless (exists $name_ids{$artist_name}) {
        my $artist = $schema->resultset('Artist')->create({
            name => $artist_name,
            mbid => $raw->{metadata}{tags}{musicbrainz_artistid}[0],
        });
        $name_ids{$artist_name} = $artist->id;
    }

#    $i++;
#    warn("\t$i. $artist_name ($artist_id)\n");

    $file =~ s|^$base||;

    $schema->resultset('Recording')->create({
        artist_id => $name_ids{$artist_name},
        file      => $file,
    });
}
