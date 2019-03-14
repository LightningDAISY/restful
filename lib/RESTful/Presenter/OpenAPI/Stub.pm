package RESTful::Presenter::OpenAPI::Stub;
use Mojo::Base 'RESTful::Presenter::Base';
use RESTful::Presenter::OpenAPI::Stub::RandomValue;
use YAML::Syck;
use List::Util;
use IO::File;

my @PARAMNAMES = qw{ status parameters requestMethod requestPath currentParameters contentType };
my %YamlCache;

my %ResponseTypes = (
  "object"    => "makeProperties",
  "array"     => "makeItems",
  "string"    => "makeString",
  "number"    => "makeNumber",
  "integer"   => "makeInteger",
  "boolean"   => "makeBoolean",
  "null"      => "makeNull",
);

__PACKAGE__->attr([@PARAMNAMES, "components", "errorMessage", "randomValue"]);

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

  $YAML::Syck::ImplicitTyping  = 1;
  $YAML::Syck::ImplicitUnicode = 1;
  $YAML::Syck::LoadBlessed     = undef;
  $YAML::Syck::ImplicitUnicode = undef;
  Load($fbody)
}
sub parseComponents
{
  my($self, $yaml) = @_;
  $self->components({});
  return if not exists $yaml->{"components"} or 
            not ref $yaml->{"components"} or
            not exists $yaml->{"components"}{"schemas"} or
            not ref $yaml->{"components"}{"schemas"}
  ;
  $self->components($yaml->{"components"}{"schemas"})
}

sub readYaml
{
  my($self) = @_;
  $YamlCache{$self->{"yamlPath"}}
}

sub path2regex
{
  my($self, $name, $names) = @_;
  push @$names, $name;
  '([^/]+?)'
}

sub pathMatch
{
  my($self, $requestUri, $paths) = @_;
  $requestUri =~ s!/$!!;
  return $requestUri if exists $paths->{$requestUri};
  my @paths = keys %$paths;
  for my $rawPath(@paths)
  {
    my $path = $rawPath;
    $path =~ s!/$!!;

    if($path !~ /\{/)
    {
      return $rawPath if $path eq $requestUri;
      next;
    }
    my $matchString = $path;
    my @names;
    $matchString =~ s!\{(.+?)\}!$self->path2regex($1, \@names)!eg;
    next if $requestUri !~ m!^$matchString/?$!;

    my @matchedValues = $requestUri =~ m!^$matchString/?$!;
    next if not scalar @matchedValues;
    for(my $i=0; $i <= $#names; $i++)
    {
      $self->parameters->{"path"} ||= {};
      $self->parameters->{"path"}{$names[$i]} = $matchedValues[$i];
    }
    return $rawPath
  }
  return
}

sub methodMatch
{
  my($self, $requestMethod, $pathStruct) = @_;
  $requestMethod = lc $requestMethod;
  for my $method(keys %$pathStruct)
  {
    return $requestMethod if $requestMethod eq lc $method
  }
  return
}

sub setParameters
{
  my($self, $category, $inputParams) = @_;
  $self->parameters->{$category} ||= {};
  for my $parameter(@{$self->currentParameters})
  {
    next if $parameter->{"in"} ne $category;
    my $name = $parameter->{"name"};
    next if not exists $inputParams->{$name};
    $self->parameters->{$category}{$name} = $inputParams->{$name};
  } 
}

sub isInteger
{
  my($self, $value) = @_;
  $value !~ /\D/ ? 1 : 0
}

sub isNumber
{
  my($self, $value) = @_;
  $value !~ /\D/ ? 1 : $value =~ /^\d+\.\d+$/ ?  1 : 0
}

sub isWithin
{
  my($self, $value, $min, $max) = @_;
  return 0 if defined $min and length $min and $value < $min;
  return 0 if defined $max and length $max and $value > $max;
  1
}

sub isWithinLength
{
  my($self, $value, $min, $max) = @_;
  return 0 if defined $min and length $min and $min > length $value;
  return 0 if defined $max and length $max and $max < length $value;
  1
}

sub isDate
{
  my($self, $value) = @_;
  $value =~ m!^\d{4}-\d{1,2}-\d{1,2}$!
}

sub isValid
{
  my($self) = @_;
  my($name, $category, $value);
  for my $struct(@{$self->currentParameters})
  {
    $name = $struct->{"name"};
    $category = $struct->{"in"};
    if(not exists $self->parameters->{$category}{$name})
    {
      $struct->{"required"} ? return $self->setErrorMessage($name . " is required.") : next
    }
    $value = $self->parameters->{$category}{$name};
    if(exists $struct->{"schema"} and ref $struct->{"schema"})
    {
      if($struct->{"schema"}{"type"} eq "integer")
      {
        $self->isInteger($value) or return $self->setErrorMessage($name . " is expected integer. " . $value);
        $self->isWithin(
          $value,
          $struct->{"schema"}{"minimum"},
          $struct->{"schema"}{"maximum"}
        ) or return $self->setErrorMessage($name . " is not within the limit. " . $value);
      }
      elsif($struct->{"schema"}{"type"} eq "number")
      {
        $self->isNumber($value) or return $self->setErrorMessage($name . " is expected number. " . $value);
        $self->isWithin(
          $value,
          $struct->{"schema"}{"minimum"},
          $struct->{"schema"}{"maximum"}
        ) or return $self->setErrorMessage($name . " is not within the limit. " . $value);
      }
      elsif($struct->{"schema"}{"type"} eq "string")
      {
        if(exists $struct->{"schema"}{"format"} and $struct->{"schema"}{"format"} eq "date")
        {
          $self->isDate($value) or return $self->setErrorMessage($name . " is not date YYYY-MM-DD " . $value)
        }
        $self->isWithinLength(
          $value,
          $struct->{"schema"}{"minLength"},
          $struct->{"schema"}{"maxLength"}
        ) or return $self->setErrorMessage($name . " is not within the limit. " . $value);
      }
    }
  }
  1
}

sub setDefault
{
  my($self) = @_;
  my($name, $category);
  for my $struct(@{$self->currentParameters})
  {
    $name = $struct->{"name"};
    $category = $struct->{"in"};
    if(exists $struct->{"schema"} and exists $struct->{"schema"}{"default"})
    {
      if(not not defined $self->parameters->{$category}{$name} or not length $self->parameters->{$category}{$name})
      {
        $self->parameters->{$category}{$name} = $struct->{"schema"}{"default"}
      }
    }
  }
}

sub makeTheResponseHeader
{
  my($self, $currentSchema) = @_;
  return {} if not exists $currentSchema->{"headers"} or "HASH" ne ref $currentSchema->{"headers"};
  my %result;
  for my $name(keys %{$currentSchema->{"headers"}})
  {
    $result{$name} = exists $currentSchema->{"headers"}{$name}{"schema"}{"example"} ?
      $currentSchema->{"headers"}{$name}{"schema"}{"example"} :
      $result{$name} = $self->schemaLoop($currentSchema->{"headers"}{$name}{"schema"})
    ;
  }
  \%result
}

sub makeProperties
{
  my($self, $currentSchema) = @_;
  exists $currentSchema->{"properties"} or return $self->debug("schema has no properties");
  my %result;
  for my $name(keys %{$currentSchema->{"properties"}})
  {
    $result{$name} = $self->schemaLoop($currentSchema->{"properties"}{$name})
  }
  \%result
}

sub makeItems
{
  my($self, $currentSchema) = @_;
  exists $currentSchema->{"items"} or return $self->debug("schema has no items");
  my @result;
  if("ARRAY" eq ref $currentSchema->{"items"})
  {
    for my $item(@{$currentSchema->{"items"}})
    {
      push @result, $self->schemaLoop($item)
    }
  }
  elsif("HASH" eq ref $currentSchema->{"items"})
  {
    return $currentSchema->{"items"}{"example"} if exists $currentSchema->{"items"}{"example"};
    push @result, $self->schemaLoop($currentSchema->{"items"})
  }
  \@result
}

#
# #/components/schemas/User
#
sub replaceRef
{
  my($self, $refKey) = @_;
  $refKey =~ s!^\#/components/!!;
  my @refKeys = split m!/!, $refKey;
  my $currentRef = $self->components;
  for(my $i=0; $i<=$#refKeys; $i++)
  {
    next if not $refKeys[$i];
    return if not exists $currentRef->{$refKeys[$i]};
    $currentRef = $currentRef->{$refKeys[$i]};
  }
  $currentRef
}

sub makeOneOf
{
  my($self, $oneOfs) = @_;
  if("ARRAY" ne ref $oneOfs)
  {
    $self->debug("oneOf is not an array");
    return ""
  }
  $self->schemaLoop($oneOfs->[int rand scalar @$oneOfs])
}

sub makeAnyOf
{
  my($self, $anyOfs) = @_;
  if("ARRAY" ne ref $anyOfs)
  {
    $self->debug("anyOf is not an array");
    return []
  }
  my $shuffledAnyOfs = List::Util::shuffle($anyOfs);
  my $currentCount = int rand scalar @$anyOfs;
  my @result;
  for my $i(0..$currentCount)
  {
    push @result, $self->schemaLoop($shuffledAnyOfs->[$i])
  }
  \@result
}

sub makeAllOf
{
  my($self, $allOfs) = @_;
  if("ARRAY" ne ref $allOfs)
  {
    $self->debug("allOf is not an array");
    return []
  }
  my @result;
  for my $allOf(@$allOfs)
  {
    push @result, $self->schemaLoop($allOf)
  }
  \@result
}

sub makeNull
{
  undef
}

sub makeString
{
  my($self, $currentSchema, $format) = @_;
  my $min = exists $currentSchema->{"minLength"} ? $currentSchema->{"minLength"} : undef;
  my $max = exists $currentSchema->{"maxLength"} ? $currentSchema->{"maxLength"} : undef;
  $self->randomValue->string($format, $min, $max)
}

sub makeInteger
{
  my($self, $currentSchema, $format) = @_;
  my $min = exists $currentSchema->{"minimum"} ? $currentSchema->{"minimum"} : undef;
  my $max = exists $currentSchema->{"maximum"} ? $currentSchema->{"maximum"} : undef;
  exists $currentSchema->{"exclusiveMinimum"} and $currentSchema->{"exclusiveMinimum"} and $min ++;
  exists $currentSchema->{"exclusiveMaximum"} and $currentSchema->{"exclusiveMaximim"} and $max --;
  $self->randomValue->integer($format, $min, $max)
}

sub makeNumber
{
  my($self, $currentSchema, $format) = @_;
  my $min = exists $currentSchema->{"minimum"} ? $currentSchema->{"minimum"} : undef;
  my $max = exists $currentSchema->{"maximum"} ? $currentSchema->{"maximum"} : undef;
  exists $currentSchema->{"exclusiveMinimum"} and $currentSchema->{"exclusiveMinimum"} and $min ++;
  exists $currentSchema->{"exclusiveMaximum"} and $currentSchema->{"exclusiveMaximim"} and $max --;
  $self->randomValue->number($format, $min, $max)
}

sub makeBoolean
{
  my($self, $currentSchema) = @_;
  $self->randomValue->boolean
}

sub schemaLoop
{
  my($self, $currentSchema) = @_;
  $currentSchema = $self->replaceRef($currentSchema->{'$ref'}) if exists $currentSchema->{'$ref'};
  return $self->makeOneOf($currentSchema->{"oneOf"}) if exists $currentSchema->{"oneOf"};
  return $self->makeAllOf($currentSchema->{"allOf"}) if exists $currentSchema->{"allOf"};
  return $self->makeAnyOf($currentSchema->{"anyOf"}) if exists $currentSchema->{"anyOf"};
  return "" if not exists $currentSchema->{"type"} or not $currentSchema->{"type"} or not exists $ResponseTypes{$currentSchema->{"type"}};
  if(exists $currentSchema->{"example"})
  {
    # for Mojo;:JSON begin
    not ref $currentSchema->{"example"} and not utf8::is_utf8 $currentSchema->{"example"} and utf8::decode $currentSchema->{"example"};
    # for Mojo;:JSON end
    return $currentSchema->{"example"};
  }
  my $methodName = $ResponseTypes{$currentSchema->{"type"}};
  my $format = exists $currentSchema->{"format"} ? $currentSchema->{"format"} : undef;
  $self->$methodName($currentSchema, $format)
}

sub makeTheResponseBody
{
  my($self, $yamlResponse, $responseType) = @_;
  return "" if "HASH" ne ref $yamlResponse->{"content"};
  $self->schemaLoop($yamlResponse->{"content"}{$responseType}{"schema"})
}

sub makeTheResponse
{
  my($self, $yamlResponses) = @_;
  my $yamlResponse = exists $yamlResponses->{"200"} ? $yamlResponses->{"200"} : exists $yamlResponses->{"default"} ? $yamlResponses->{"default"} : undef;
  $yamlResponse or return $self->setErrorMessage("it has no response block (200 || default)");
  my $responseType   = (keys %{$yamlResponse->{"content"}})[0];
  my $responseHeader = $self->makeTheResponseHeader($yamlResponse) or return;
  my $responseBody   = $self->makeTheResponseBody($yamlResponse, $responseType) or return;

  +{
    type   => $responseType,
    header => $responseHeader,
    body   => $responseBody,
  }
}

sub makeTheErrorResponse
{
  my($self, $code, $message) = @_;
  $code ||= $self->status || 404;
  my $yamlResponses = $YamlCache{$self->{"yamlPath"}}{"paths"}{$self->requestPath}{$self->requestMethod}{"responses"};
  my $yamlResponse = exists $yamlResponses->{$code} ?
    $yamlResponses->{$code} :
    exists $yamlResponses->{"default"} ?
      $yamlResponses->{"default"} :
      undef
  ;
  $yamlResponse or do {
    $self->debug("it has no response block ($code || default)");
    return
  };
  my $responseType   = (keys %{$yamlResponse->{"content"}})[0];
  my $responseHeader = $self->makeTheResponseHeader($yamlResponse) or return;
  my $responseBody   = $self->makeTheResponseBody($yamlResponse, $responseType) or return;
  $responseBody->{"message"}      ||= $message;
  $responseBody->{"errorMessage"} ||= $message;

  +{
    type   => $responseType,
    header => $responseHeader,
    body   => $responseBody,
  }
}

sub error
{
  my($self, $code, $message) = @_;
  $self->status($code) if $code;
  $self->makeTheErrorResponse($code, $message) || +{
    type   => "application/json",
    header => {},
    body   => +{
      code    => $code,
      message => "$message ($code block is not found.)",
    }
  }
}

#
# my $response = $ins->run(
#   uri => $self->_getRequestPath,
#   method => $self->req->method,
#   cookies => {
#     sessionId => "xthhtgtw",
#   },
#   headers    => {
#     X-UserID => 123,
#   },
#   params     => {
#     page    => 2,
#     limit   => 50,
#     refresh => 1,
#   },
# )
#
sub run
{
  my($self, %args) = @_;
  $self->status(200);
  $self->parameters({});
  $self->parseComponents($YamlCache{$self->{"yamlPath"}});
  my $paths  = $YamlCache{$self->{"yamlPath"}}{"paths"};
  my $path   = $self->pathMatch($args{"uri"}, $paths) or return $self->error(404, $args{"uri"} . " path is not matched.");
  $self->requestPath($path);
  my $method = $self->methodMatch($args{"method"}, $paths->{$path}) or return $self->error(404, $args{"uri"} . " method is not matched.");
  $self->requestMethod($method);

  $self->currentParameters($paths->{$path}{$method}{"parameters"} || []);
  $self->setParameters("query",  $args{"params"});
  $self->setParameters("cookie", $args{"cookies"});
  $self->setParameters("header", $args{"headers"});
  $self->setDefault;
  $self->isValid or return $self->error(400, $self->errorMessage);
  $self->makeTheResponse($paths->{$path}{$method}{"responses"}) or return $self->error(406, $self->errorMessage)
}

#
# my $ins = RESTful::Presenter::OpenAPI::Stub->new(
#   yamlPath => "/var/www/yamls/x.yml"
# );
#
sub new
{
  my($class, %args) = @_;
  my $self = bless \%args, $class;
  return if not $args{"yamlPath"};
  $YamlCache{$args{"yamlPath"}} = undef if exists $args{"refresh"} and $args{"refresh"};
  $YamlCache{$args{"yamlPath"}} ||= $self->_parseYaml($args{"yamlPath"}) or return;
  $self->randomValue(RESTful::Presenter::OpenAPI::Stub::RandomValue->new);
  $self
}

1
__END__

newしてrunします。

仕様書(YAML)にあって入力に無い値はundefになります。
入力にあって仕様書(YAML)に無い値は捨てられます。

OpenAPIの型仕様が変わったらisValidから下を修正します。


