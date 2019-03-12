package RESTful::Presenter::OpenAPI::Stub::RandomValue::Integer;
use Mojo::Base 'RESTful::Presenter::Base';

my @CHARS = (0..9);
my $CHARS = scalar @CHARS;

sub _int
{
  my($self, $min, $max) = @_;
  $min ||= 5;
  $max = $min if not defined $max;
  if($max < $min) { my $tmp = $min; $min = $max; $max = $tmp }
  my $currentLength = $min + int rand($max - $min + 1);

  my $result = '';
  for(my $i=0; $i<$currentLength; $i++)
  {
    $result .= $CHARS[int rand $CHARS]
  }
  int $result
}

sub _int32
{
  my($self, $min, $max) = @_;
  $min ||= 1;
  $max ||= 9;
  $self->_int($min, $max)
}

sub _int64
{
  my($self, $min, $max) = @_;
  $min ||= 1;
  $max ||= 19;
  $self->_int($min, $max)
}

1

__END__

$ins->string("string")
