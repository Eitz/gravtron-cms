package Gravtron::CMS;
use FindBin;
use DateTime;

use Mojo::Base 'Mojolicious::Plugin';

use Gravtron::Gravtron;

use Gravtron::Config;
use Gravtron::CMS::Helpers;
use Gravtron::CMS::Controller;
use Gravtron::CMS::Persistence;

has 'gravtron';

sub register {
	my ($self, $app) = @_;

	$app->log->debug("Gravtron::CMS: Plugin loading started");

	# register gravtron
	unless ($self->gravtron) {
		my $G = Gravtron::Gravtron->new(app => $app);
		$self->gravtron($G);
	}

	push @{$self->gravtron->plugins_loaded}, 'Gravtron::CMS';

	# start persistence
	my $persistence = Gravtron::CMS::Persistence->new(context => $self);

	# prepare helpers
	my $helpers = Gravtron::CMS::Helpers->new(persistence => $persistence);
	$self->gravtron->set_helper({cms => $helpers});

	# load config
	if ($self->gravtron->config->{cms}){
		$self->gravtron->config->{cms}->{home} = $self->gravtron->config->{home}.'/CMS';
	} else {
		$self->gravtron->config->{cms} = {};
		$self->gravtron->config->{cms}->{prefix} = '';
		$self->gravtron->config->{cms}->{home} = $self->gravtron->config->{home}.'/CMS';
	}
	
	my $prefix = $self->config->{cms}->{prefix};
	my $home = $self->config->{home};

	# static serve
	push @{$app->static->paths}, "$home/assets";

	# controller
	push @{$app->routes->namespaces}, 'Gravtron::CMS';

	# templates
	push @{$app->renderer->paths}, "$home/templates";

	# routes
	my $r = $app->routes;
	if (!@{$r->children} && ($prefix eq '' || $prefix eq '/')){
		$app->log->error('CMS: Warning, the plugin was loaded before other routes'.
						 ' were added and no PREFIX was configured. The CMS\'s '.
						 'placeholders will overwrite anything after "/". '.
						 'Suggestion: Load the plugin after everything.');	
	}

	unless ($prefix eq '' || $prefix eq '/'){
		$r = $r->under($prefix);
	}
	
	$r->get("/")
		->to(controller => 'CMSController', action => 'index')
		->name("cms_root");
	
	$r->get("/:categoria/")
		->to(controller => 'CMSController', action => 'category')
		->name("cms_category");

	$r->get("/:categoria/:post")
		->to(controller => 'CMSController', action => 'post')
		->name("cms_post");

	$app->log->debug("Gravtron::CMS: Loading complete");
}

1;