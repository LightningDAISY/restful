package RESTful::Hooks::Cors;
use Mojo::Base -base;

my %headerNames = (
  "Origin" => "Access-Control-Allow-Origin",
  "Access-Control-Request-Headers" => "Access-Control-Allow-Headers",
  "Access-Control-Allow-Credentials" => "Access-Control-Allow-Credentials"
);

sub addHeader
{
  my($class, $c) = @_;
  my $allowedOrigin = 0;
  for my $name(keys %headerNames)
  {
    my $requestedValue = $c->req->headers->header($name);
    if($requestedValue)
    {
      $allowedOrigin = 1;
      $c->res->headers->add(
        $headerNames{$name} => $requestedValue
      );
    }
  }
  $allowedOrigin
}

1
__END__

=SYNOPSIS

  use RESTful::Hooks::Cors;
  
  $self->hook(
    before_dispatch => sub {
      my($c) = @_;
      RESTful::Hooks::Cors->addHeader($c)
    }
  );


