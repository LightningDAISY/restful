package RESTful::Controller::Stub;
use Mojo::Base "RESTful::Controller::Base";
use RESTful::Presenter::OpenAPI;

has myUri => sub {"/stub"};

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
  for my $name(keys %$headers)
  {
    $self->res->headers->header($name => $headers->{$name})
  }
}

# GET /ex/stub/example.yaml/user/list
sub index
{
  my($self, %args) = @_;
  my $requestPath = $self->getRequestPath;
  my $yamlPath = $self->getYamlPath or return $self->error("invalid file name");
  my $yamlFullPath = $ENV{"MOJO_HOME"} . "/" . $self->config->{"yamlDirStub"} . $yamlPath;
  my $server = RESTful::Presenter::OpenAPI->new->stub(
    yamlPath => $yamlFullPath,
    refresh  => 1,
  ) or return $self->error("$yamlFullPath is not found. (or invalid format)");

  my $jsonBody;
  my $contentType = $self->req->headers->header("Content-Type");
  if($contentType and $contentType eq "application/json")
  {
    my $type = ref $self->req->json;
    return $self->error("invalid json format") if not $type;
    return $self->error("invalid json type " . $type) if "HASH" ne $type;
    $jsonBody = $self->req->json;
  }

  # $self->cookie(userId  => '123456', {expires => time + 3600});

  my $info = $server->basicAuthInfo(
    "uri"    => $requestPath,
    "method" => $self->req->method,
  );
  if($info and exists $info->{"example"}{"realm"} and exists $info->{"example"}{"username"} and exists $info->{"example"}{"password"})
  {
    $self->debug($self->req->headers->to_hash);
    return $self->render(
      status => 401,
      text => "unauthorized",
    ) unless $self->basic_auth(
      $info->{"example"}{"realm"} => {
        username => $info->{"example"}{"username"},
        password => $info->{"example"}{"password"},
      }
    )
  }

  my $res = $server->run(
      uri     => $requestPath,
      method  => $self->req->method,
      params  => $self->req->query_params->to_hash,
      json    => $jsonBody,
      form    => $self->req->body_params->to_hash,
      headers => $self->req->headers->to_hash,
      cookies => $self->getAllCookies,
  ) or return $self->error($server->errorMessage);
  my $charsetHeader = $self->config->{"charset"} ?
    ";charset=" . $self->config->{"charset"} :
    ""
  ;
  $self->res->headers->header("Content-Type" => $res->{"type"} . $charsetHeader) if $res->{"type"};
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


