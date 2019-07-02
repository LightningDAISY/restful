package RESTful::Hooks::Cors;
use Mojo::Base -base; # qw{ RESTful::Base };
use Mojo::Base qw{ RESTful::Base };

my %headerNames = (
  "Origin" => "Access-Control-Allow-Origin",
  "Access-Control-Request-Headers" => "Access-Control-Allow-Headers",
  "Access-Control-Allow-Credentials" => "Access-Control-Allow-Credentials"
);

sub addHeader
{
  my($self, $c) = @_;
  my $allowedOrigin = 0;
  for my $name(keys %headerNames)
  {
    my $requestedValue = $c->req->headers->header($name);
    if($requestedValue and length $requestedValue)
    {
      $allowedOrigin = 1;
      $self->debug($name . " " . $requestedValue);
      $c->res->headers->add(
        $headerNames{$name} => $requestedValue
      );
    }
  }
  $allowedOrigin
}

1
__END__

