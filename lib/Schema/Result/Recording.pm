package Schema::Result::Recording;
use parent 'DBIx::Class::Core';

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

1;
