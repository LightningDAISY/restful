package RESTful::Presenter::OpenAPI::Stub::RandomValue;
use RESTful::Presenter::OpenAPI::Stub::RandomValue::String;
use RESTful::Presenter::OpenAPI::Stub::RandomValue::Integer;
use RESTful::Presenter::OpenAPI::Stub::RandomValue::Number;
use RESTful::Presenter::OpenAPI::Stub::RandomValue::Boolean;
use Mojo::Base 'RESTful::Presenter::Base';
__PACKAGE__->attr(["errorMessage"]);

has _string => sub {
  RESTful::Presenter::OpenAPI::Stub::RandomValue::String->new
};

has _integer => sub {
  RESTful::Presenter::OpenAPI::Stub::RandomValue::Integer->new
};

has _number => sub {
  RESTful::Presenter::OpenAPI::Stub::RandomValue::Number->new
};

has _boolean => sub {
  RESTful::Presenter::OpenAPI::Stub::RandomValue::Boolean->new
};

sub setErrorMessage
{
  my($self, $message) = @_;
  $message
}

sub string
{
  my($self, $format, @argv) = @_;
  $format ||= "string";
  my $lcFormat = "_" . lc $format;
  $self->_string->can($lcFormat) ? $self->_string->$lcFormat(@argv) : $self->_string->_string(@argv)
}

sub integer
{
  my($self, $format, @argv) = @_;
  $format ||= "int32";
  my $lcFormat = "_" . lc $format;
  $self->_integer->can($lcFormat) ? $self->_integer->$lcFormat(@argv) : $self->_integer->_int32(@argv)
}

sub number
{
  my($self, $format, @argv) = @_;
  $format ||= "float";
  my $lcFormat = "_" . lc $format;
  $self->_number->can($lcFormat) ? $self->_number->$lcFormat(@argv) : $self->_number->_float(@argv)
}

sub boolean
{
  my($self) = @_;
  $self->_boolean->boolean
}

1

__END__

$ins->string("string")
