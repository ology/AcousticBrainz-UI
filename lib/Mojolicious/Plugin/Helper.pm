package Mojolicious::Plugin::Helper;
use Mojo::Base 'Mojolicious::Plugin';

use Encoding::FixLatin 'fix_latin';

use Schema;

sub register {
  my ($self, $app, $conf) = @_;

  my $config = $app->config;

  $app->helper(schema => sub {
    return state $dbi_connection = Schema->connect('dbi:SQLite:dbname=/home/gene/sandbox/dev/Music/ab-low-level.db','','');
  });

  $app->helper(rs => sub {
    return shift->schema->resultset(@_)
  });

  $app->helper(fix_latin => sub {
    my $self = shift;
    return scalar fix_latin(@_)
  });
}

1;
