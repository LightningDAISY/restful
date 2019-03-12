package RESTful::Presenter::OpenAPI::Stub::RandomValue::Number;
use Mojo::Base 'RESTful::Presenter::Base';

sub _number
{
  my($self, $min, $max, $numberOfDigit) = @_;
  my $limit = $max - $min;
  my $integerPart = int(rand($limit)) + $min;
  return $integerPart if $numberOfDigit <= length $integerPart;

  my $limitOfFlactionalDigit = 10 ** ($numberOfDigit - length $integerPart) - 2;
  my $flactionalPart = int(rand $limitOfFlactionalDigit) + 1;
  $flactionalPart =~ s/0+$//;
  $integerPart . "." . $flactionalPart
}

sub _float
{
  my($self, $min, $max) = @_;
  $min ||= 1;
  $max ||= 999999;
  $self->_number($min, $max, 7)
}

sub _double
{
  my($self, $min, $max) = @_;
  $min ||= 1;
  $max ||= 9999999999999;
  $self->_number($min, $max, 14)
}

1

__END__

