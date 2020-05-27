package Schema::Result::Recording;
use parent 'DBIx::Class::Core';

use File::Basename;
use File::Slurper 'read_text';
use JSON::MaybeXS;

__PACKAGE__->table('recordings');

__PACKAGE__->add_columns(
    id        => { data_type => 'int', is_nullable => 0, is_serializable => 1, is_auto_increment => 1 },
    artist_id => { data_type => 'int', is_nullable => 0, is_serializable => 1 },
    file      => { data_type => 'text', is_nullable => 0, is_serializable => 1 },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to(
    artist => 'Schema::Result::Artist',
    { 'foreign.id' => 'self.artist_id' },
    { cascade_delete => 0, cascade_copy => 0 }
);

sub json {
    my $self = shift;
    my $prefix = shift || '';
    my $content = read_text($prefix . $self->file);
    my $raw = decode_json($content);
    return $raw;
}

sub mbid_from_file {
    my $self = shift;
    my $mbid = basename($self->file, '.json');
    $mbid =~ s/^(.+?)-\d+$/$1/;
    return $mbid;
}

1;
