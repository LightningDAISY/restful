package RESTful;
use RESTful::Hooks::Cors;
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

  $self->plugin('BasicAuthPlus');

  {
    package RESTful::Base;
    sub config { $config };
  }

  $self->hook(
    before_dispatch => sub {
      my($c) = @_;
      RESTful::Hooks::Cors->addHeader($c);
    }
  );

  # Router
  my $r = $self->routes;
  $r->any('/stub/*uri/README')->to('readme#index');
  $r->any('/stub/*uri')->to('stub#index');
  $r->any('/api/documents/*uri')->to('api#documents');
  $r->any('/api/repos')->to('api#repos');
}

1;
