package RESTful::Presenter::Base;
use IO::File;
use YAML::Syck;
use Mojo::Base qw{ RESTful::Base };

__PACKAGE__->attr(["errorMessage"]);

$YAML::Syck::ImplicitTyping  = 1;
$YAML::Syck::ImplicitUnicode = 1;
$YAML::Syck::LoadBlessed     = undef;
$YAML::Syck::ImplicitUnicode = undef;

sub setErrorMessage
{
  my($self, $errorMessage) = @_;
  $self->errorMessage($errorMessage);
  return
}

sub _parseYaml
{
  my($self, $filePath) = @_;
  warn "Reading $filePath ...";
  my $fh = IO::File->new($filePath, "r") or return $self->setErrorMessage($filePath . " is not found.");
  my $fbody = '';
  my $buf;
  $fbody .= $buf while read $fh, $buf, 100;
  close $fh;

  Load($fbody)
}

1

