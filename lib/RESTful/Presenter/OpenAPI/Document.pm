package RESTful::Presenter::OpenAPI::Document;
use Mojo::Base 'RESTful::Presenter::Base';
use YAML::Syck;
use File::Find;

#
# my $list = $ins->fileList(extensions => ["yaml", "yml"])
#

sub fileList
{
  my($self, %args) = @_;
  my $extensions = exists $args{"extensions"} ? $args{"extensions"} : [];
  my $path = $self->{"dirPath"};
  my @result;
  my $wanted = sub {
    my $fname = $_;
    for my $extension(@$extensions)
    {
      push @result, $File::Find::name if $fname =~ /\.$extension$/
    }
  };
  find({ wanted => $wanted, follow => 1 }, $path);
  \@result
}

sub yamlDetails
{
  my($self) = @_;
  my $filePaths = $self->fileList(extensions => ["yaml", "yml"]);
  my %result;
  my $requestPath = $self->{"dirPath"};
  $requestPath =~ s/^$self->{"dirPrefix"}//;
  $YAML::Syck::ImplicitUnicode = 1;
  for my $filePath(@$filePaths)
  {
    my %detail;
    my $yaml = $self->_parseYaml($filePath);
    for my $path(keys %{$yaml->{"paths"}})
    {
      for my $method(keys %{$yaml->{"paths"}{$path}})
      {
        my $yamlPath = $filePath;
        $yamlPath =~ s/^$self->{"dirPath"}//;
        my $yamlUri = $self->config->{"fileUri"} . $requestPath . $yamlPath;
        $result{$path} = +{
          method    => uc($method),
          path      => $path,
          title     => $yaml->{"paths"}{$path}{$method}{"summary"} || "-",
          description => $yaml->{"paths"}{$path}{$method}{"description"} || "-",
          yamlUri   => $yamlUri,
          viewerUri => $self->config->{"viewerUri"} . $yamlUri
        }
      }
    }
  }
  $YAML::Syck::ImplicitUnicode = undef;
  \%result
}

#
# my $ins = RESTful::Presenter::OpenAPI::Document->new(
#   dirPrefix => "/var/www/restful/yamls/static/files",
#   dirPath => "/static/files/master"
# );
#
sub new
{
  my($class, %args) = @_;
  return if not exists $args{"dirPath"};
  return if not -d $args{"dirPath"};
  $args{"dirPrefix"} //= "";
  bless \%args, $class
}

1

__END__

