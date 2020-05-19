package Schema::Result::Artist;
use parent 'DBIx::Class::Core';

__PACKAGE__->table('artists');

__PACKAGE__->add_columns(
    id   => { data_type => 'int', is_nullable => 0, is_serializable => 1, is_auto_increment => 1 },
    name => { data_type => 'text', is_nullable => 0, is_serializable => 1 },
    mbid => { data_type => 'text', is_nullable => 1, is_serializable => 1 },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->has_many(
  recordings => 'Schema::Result::Recording', 'artist_id',
  { cascade_delete => 0, cascade_copy => 0 }, #, where => {finished_at => {'!=' => undef}} } #, order_by => 'created_at' },
);

1;
