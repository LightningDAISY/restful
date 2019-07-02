package RESTful::Controller::Api;
use Mojo::Base "RESTful::Controller::Base";
use RESTful::Presenter::OpenAPI;

has myUri => sub {"/api"};
has repoNames => sub {
  my @repos = qw{
    master develop testshop
    team/dev01 team/dev02 team/dev03 team/dev04 team/dev05
    team/dev06 team/dev07 team/dev08 team/dev09 team/dev10
    team/dev11 team/dev12
  };
  \@repos
};

sub notfound
{
  my($self, $message) = @_;
  $message ||= $self->req->url . " is not found.";
  $self->render(
    status => 404,
    text   => $message,
  )
}

sub repos
{
  my($self, %args) = @_;
  my %json;
  for my $name(@{$self->repoNames})
  {
    $json{"/" . $name} = {
      method      => "GET",
      path        => "/" . $name,
      title       => $name,
      viewerUri   => "/docs/repos/#/" . $name,
      description => "-",
    }
  }
  $self->render(
    status => 200,
    json => \%json,
  )
}

sub documents
{
  my($self, %args) = @_;
  my $dirPath = $self->getDirectoryPath("/documents") or return $self->notfound;
  my $api = RESTful::Presenter::OpenAPI->new->document(
    dirPath   => $dirPath,
    dirPrefix => $ENV{"MOJO_HOME"} . "/" . $self->config->{"yamlDir"},
    refresh   => 1,
  ) or return $self->notfound;
 
  $self->render(
    status => 200,
    json => $api->yamlDetails,
  )
}

1
__END__
