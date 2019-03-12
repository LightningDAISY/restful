package RESTful::Presenter::OpenAPI;
use Mojo::Base 'RESTful::Presenter::Base';
use RESTful::Presenter::OpenAPI::Stub;

sub stub
{
  my($self, %args) = @_;
  RESTful::Presenter::OpenAPI::Stub->new(%args)
}

1
__END__


