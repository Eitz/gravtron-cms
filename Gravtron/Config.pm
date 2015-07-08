package Gravtron::Config;
use FindBin;
use DateTime;

use Mojo::Base -base;

use Gravtron::Util;

has 'gravtron';
has '_config';

sub definitions {
	my $self = shift;

	if (defined $self->_config){
		return $self->_config;
	}

	return $self->prepare_config;
}


sub prepare_config {
	my $self = shift;

	my $root = "$FindBin::Bin/Gravtron";

	my $filename = "$root/gravtron.config";

	my $util = Gravtron::Util->new;
	my $config = $util->open_file($filename);

	$config = eval { eval "$config" };

	if (!$config || (ref $config ne 'HASH') ) {
		
		if ($self->gravtron->app){
			$self->gravtron->app->log->error("Problem loading config file('gravtron.config')");
		}
		$config = {};
	}

	$config->{home} = "$root";
	$self->_config($config);

	return $self->_config;
}

1;