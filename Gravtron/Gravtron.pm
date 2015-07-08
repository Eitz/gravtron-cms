package Gravtron::Gravtron;
use FindBin;
use DateTime;

use Mojo::Base -base;

has 'app';
has 'configurer';
has 'loaded_plugins' => sub { [] };

sub set_helper{
	my $self = shift;
	my $args = shift;

	for my $key (keys $args){
		$self->app->helper($key => sub { $args->{$key} });	
	}	
}

sub config {
	my $self = shift;

	unless ($self->configurer){
		$self->configurer( Gravtron::Config->new(gravtron => $self) );
	}
	$self->configurer->definitions;
}

1;