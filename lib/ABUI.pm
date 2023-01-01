package ABUI;
use Mojo::Base 'Mojolicious';

sub startup {
  my $self = shift;

  my $config = $self->plugin('Config');

  $self->plugin('Helper');

  $self->secrets($config->{secrets});

  my $r = $self->routes;
  $r->get('/')->to('access#main');
  $r->get('/size')->to('access#size');
}

1;
