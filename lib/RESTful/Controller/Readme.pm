package RESTful::Controller::Readme;
use Mojo::Base "RESTful::Controller::Base";
use RESTful::Presenter::OpenAPI;

has myUri => sub {"/stub"};
has outerUri => sub {
    my($self) = @_;
    $self->config->{"outerUri"};
};
has outerUri => sub {
  my($self) = @_;
  $self->config->{"outerUri"}
};

sub error
{
  my($self, $message) = @_;
  $self->stash("message" => $message);
  $self->render(template => 'readme/error')
}

sub index
{
  my($self) = @_;
  my $requestPath = $self->getRequestPath;
  my $yamlPath = $self->getYamlPath or return $self->error("invalid file name");
  my $yamlFullPath = $ENV{"MOJO_HOME"} . "/" . $self->config->{"yamlDirStub"} . $yamlPath;
  my $server = RESTful::Presenter::OpenAPI->new->stub(
    yamlPath => $yamlFullPath,
    refresh  => 1,
  ) or return $self->error("$yamlFullPath is not found. (or invalid format)");

  $self->stash("uriPrefix" => $self->outerUri . $yamlPath);
  $self->stash("yamlPath"  => $yamlFullPath);
  $self->stash("server"    => $server);
  $self->render(template   => 'readme/index')
}

1

