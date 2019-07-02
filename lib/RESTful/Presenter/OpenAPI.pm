package RESTful::Presenter::OpenAPI;
use Mojo::Base 'RESTful::Presenter::Base';
use RESTful::Presenter::OpenAPI::Stub;
use RESTful::Presenter::OpenAPI::Document;

sub stub
{
  my($self, %args) = @_;
  RESTful::Presenter::OpenAPI::Stub->new(%args)
}

sub document
{
  my($self, %args) = @_;
  RESTful::Presenter::OpenAPI::Document->new(%args)
}

1
__END__


