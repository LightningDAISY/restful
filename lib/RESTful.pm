package RESTful;
use Mojo::Base 'Mojolicious';

# This method will run once at server start
sub startup
{
  my($self) = @_;

  # SET WARN
  $SIG{'__WARN__'} = sub {
    unshift @_, $self->app->log;
    goto $self->app->log->can('warn');
  };

  # Load configuration from hash returned by config file
  my $config = $self->plugin('Config');

  # Configure the application
  $self->secrets($config->{secrets});

  # Router
  my $r = $self->routes;
  $r = $r->any('/ex');
  $r->any('/stub/*uri')->to('stub#index');
}

1;
