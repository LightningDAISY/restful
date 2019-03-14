package RESTful::Controller::Stub;
use Mojo::Base "RESTful::Controller::Base";
use RESTful::Presenter::OpenAPI;

has myUri => sub {"/stub"};

sub getYamlPath
{
  my($self) = @_;
  my $baseUri = $self->config->{"baseUri"} . $self->myUri;
  my $yamlPath = $self->req->url;
  $yamlPath =~ s!.*$baseUri!!;
  return if $yamlPath !~ m!(.+\.ya?ml)!;
  $1
}

sub getRequestPath
{
  my($self) = @_;
  my($uri) = split m!\?!, $self->req->url, 2;
  my($trash, $params) = split m!/(?:.+?\.ya?ml)!, $uri, 2;
  $params || '/'
}

sub error
{
  my($self, $message) = @_;
  $self->render(
    status => 405,
    json => {
      error => {
        code    => 405,
        message => $message,
      }
    },
  )
}

sub getAllCookies
{
  #Cookie":"user=nacci; user2=nacci2
  my($self) = @_;
  my $headers = $self->req->headers->to_hash;
  $headers->{"Cookie"} or return {};
  
  my @pairs = split /;\s+/, $headers->{"Cookie"};
  my %cookies;
  for my $pair(@pairs)
  {
    my($key,$value) = split /=/, $pair;
    $cookies{$key} = $value
  }
  \%cookies
}

sub setHeaders
{
  my($self, $headers) = @_;
  for my $name(%$headers)
  {
    $self->res->headers->header($name => $headers->{$name})
  }
}

# GET /ex/stub/example.yaml/user/list
sub index
{
  my($self, %args) = @_;
  my $yamlPath = $self->getYamlPath or return $self->error("invalid file name");
  my $yamlFullPath = $ENV{"MOJO_HOME"} . "/" . $self->config->{"yamlDir"} . $yamlPath;
  my $server = RESTful::Presenter::OpenAPI->new->stub(
    yamlPath => $yamlFullPath,
    refresh  => 1,
  ) or return $self->error("$yamlFullPath is not found. (or invalid format)");

  # $self->cookie(userId  => '123456', {expires => time + 3600});

  my $res = $server->run(
      uri     => $self->getRequestPath,
      method  => $self->req->method,
      params  => $self->req->params->to_hash,
      headers => $self->req->headers->to_hash,
      cookies => $self->getAllCookies,
  ) or return $self->error($server->errorMessage);
  $self->res->headers->header("content_type" => $res->{"type"}) if $res->{"type"};
  $self->setHeaders($res->{"header"});
  $self->render(
    status => $server->status,
    json   => $res->{"body"},
  )
}

1

__END__

sudo cpan YAML::Syck
sudo cpan Mojolicious
cd restful

# start
hypnotoad script/restful

# stop
hypnotoad -s script/restful


