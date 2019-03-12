package RESTful::Base;
use feature qw{ say state switch current_sub };
use Mojo::Util qw{ dumper };
use Mojo::Base -base;
use Mojo::UserAgent;

has ua => sub { Mojo::UserAgent->new };

__PACKAGE__->attr([qw{ errorCode errorMessage }]);

sub debug
{
	my($self,$arg) = @_;
	my $string = ref($arg) ? dumper($arg) : $arg;
	my @caller = caller(0);
	scalar @caller or @caller = ('?','?','?');
	warn sprintf '%s at %s line %s', $string, $caller[1], $caller[2];
	$self
}

sub new
{
	my($class,%args) = @_;
	bless \%args, $class
}

1

