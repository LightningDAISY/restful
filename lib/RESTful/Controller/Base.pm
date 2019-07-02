package RESTful::Controller::Base;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::Util qw{ dumper };
use Mojo::JSON;
use feature qw{ say state switch current_sub };

sub debug
{
	my($self,$arg) = @_;
	my $string = ref($arg) ? dumper($arg) : $arg;
	my @caller = caller(0);
	scalar @caller or @caller = ('?','?','?');
	warn sprintf '%s at %s line %s', $string, $caller[1], $caller[2];
	$self
}

#
# /stub/xxx?a=A&b=B -> /stub/xxx
#
sub _uri2path
{
	my($self, $uri) = @_;
	my($path, $params) = split(m!\?!, $uri, 2);
	$path
}

sub _flexUri
{
	my($self, $uri, $myUriNum) = @_;
	my $path = $self->_uri2path($uri);
	my @pathes = split(m!/!, $path, $myUriNum + 2);
	pop @pathes
}

sub _yamlAndRequestPath
{
	my($self, $path) = @_;
	my @pathes = split m!/!, $path;
	my $yamlNum = 0;
	for(my $i=0; $i<=$#pathes; $i++)
	{
		if($pathes[$i] =~ m!\.ya?ml$!i)
		{
			$yamlNum = $i;
			last;
		}
	}
	my @yamlUris  = splice @pathes, 0, $yamlNum + 1;
	my $yamlUri = join "/", @yamlUris;
	my $reqPath = join "/", "", @pathes;
	($yamlUri, $reqPath)
}

sub _isJSONRequest
{
	my($self) = @_;
	$self->req->headers->content_type eq "application/json" ?
	1 : $self->req->headers->content_type eq "x-application/json" ?
	1 : 0
}

sub _parseJSON
{
	my($self, $text) = @_;
	my $struct = eval { Mojo::JSON::decode_json($text) };
	if($@)
	{
		warn $@;
		return
	}
	$struct
}

sub _parseJSONBody
{
	my($self,$text) = @_;
	my $hash = $self->req->params->to_hash;
	my $json = $self->_parseJSON;
	my %parsed = (%$json, %$hash);
	\%parsed
}

sub getYamlPath
{
  my($self) = @_;
  my $baseUri = $self->config->{"baseUri"} . $self->myUri;
  my $yamlPath = $self->req->url;
  $yamlPath =~ s!.*$baseUri!!;
  return if $yamlPath !~ m!(.+\.ya?ml)!;
  $1
}

sub getDirectoryPath
{
  my($self, $apiUri) = @_;
  $apiUri ||= "";
  my $baseUri = $self->config->{"baseUri"} . $self->myUri . $apiUri;
  my $dirPath = $self->req->url;
  $dirPath =~ s!.*$baseUri!!;
  $dirPath =~ s!/+$!!;
  $dirPath = $ENV{"MOJO_HOME"} . "/" . $self->config->{"yamlDir"} . $dirPath;
  $self->debug($dirPath);
  return -d $dirPath ? $dirPath : undef
}

sub getRequestPath
{
  my($self) = @_;
  my($uri) = split m!\?!, $self->req->url, 2;
  my($trash, $params) = split m!/(?:.+?\.ya?ml)!, $uri, 2;
  $params || '/'
}

1

