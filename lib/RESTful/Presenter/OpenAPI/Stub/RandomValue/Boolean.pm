package RESTful::Presenter::OpenAPI::Stub::RandomValue::Boolean;
use Mojo::Base 'RESTful::Presenter::Base';

sub boolean
{
  my($self, $min, $max) = @_;
  int rand(2) ? Mojo::JSON->true : Mojo::JSON->false
}

1

__END__

