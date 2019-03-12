package RESTful::Presenter::OpenAPI::Stub::RandomValue::String;
use Mojo::Base 'RESTful::Presenter::Base';

my @CHARS = ("A".."Z", "a".."z", 0..9);
my @UUIDCHARS = ("a".."f", 0..9);
my $CHARS = scalar @CHARS;
my $UUIDCHARS = scalar @UUIDCHARS;

sub _string
{
  my($self, $min, $max) = @_;
  $min ||= 8;
  $max = $min if not defined $max;
  if($max < $min) { my $tmp = $min; $min = $max; $max = $tmp }
  my $currentLength = $min + int rand($max - $min + 1);

  my $result = '';
  for(my $i=0; $i<$currentLength; $i++)
  {
    $result .= $CHARS[int rand $CHARS]
  }
  $result
}

sub _email
{
  my($self) = @_;
  my $rands = sub {
    my($length) = @_;
    my $result = '';
    for(my $i=$length; $i; $i--)
    {
      $result .= $CHARS[int rand $CHARS];
    }
    $result
  };
  sprintf "%s@%s.%s", $rands->(8), $rands->(6), $rands->(3)
}

sub _uuid
{
  my($self) = @_;
  my $rands = sub {
    my($length) = @_;
    my $result = '';
    for(my $i=$length; $i; $i--)
    {
      $result .= $UUIDCHARS[int rand $UUIDCHARS];
    }
    $result
  };
  my @results;
  for my $length(qw{ 8 4 4 4 12 })
  {
    push @results, $rands->($length)
  }
  join "-", @results
}

sub _date
{
  my($self, @argv) = @_;
  my($sec, $min, $hour, $day, $month, $year) = localtime int rand time;
  sprintf "%d-%02d-%02d", $year+1900, $month, $day
}

sub _datetime
{
  my($self, @argv) = @_;
  my($sec, $min, $hour, $day, $month, $year) = localtime int rand time;
  sprintf "%d-%02d-%02dT%02d:%02d:%02d", $year+1900, $month, $day, $hour, $min, $sec
}

1

__END__

$ins->string("string")
