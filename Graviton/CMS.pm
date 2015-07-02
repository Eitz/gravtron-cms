package Graviton::CMS;
use FindBin;
use DateTime;

use Mojo::Base 'Mojolicious::Plugin';

use Graviton::CMS::Helpers;
use Graviton::CMS::Controller;
use Graviton::CMS::Persistence;

has 'config';

sub register {
	my ($self, $app) = @_;

	$app->log->debug("CMS: Plugin loading started");

	# start persistence
	my $persistence = Graviton::CMS::Persistence->new(context => $self);

	# prepare helpers
	my $helpers = Graviton::CMS::Helpers->new(persistence => $persistence);
	$app->helper(cms => sub { 
		$helpers
	});

	# prepare config
	$self->config( $self->prepare_config($app) );
	
	my $prefix = $self->config->{prefix};
	my $home = $self->config->{cms_home};

	# static serve
	push @{$app->static->paths}, "$home/assets";

	# controller
	push @{$app->routes->namespaces}, 'Graviton::CMS';

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

	$app->log->debug("CMS: Loading complete");
}

sub prepare_config {
	my ($self, $app) = @_;

	my $root = "$FindBin::Bin/Graviton/CMS";

	my $filename = "$root/cms.config";

	my $config = $self->open_file($filename);

	$config = eval { eval "$config" };

	if ($config && defined $config->{prefix}){
		
		$config->{prefix} = "$config->{prefix}";
		$config->{prefix} =~ s|\/\/|\/|g;

	} else {
		$app->log->error("Problem loading config file('cms.config'): ".
						 "It has to be in the same folder as CMS.pm ".
						 "and it must have 'prefix'.");
		$config = {
			prefix => '/blog'
		};
	}

	$config->{cms_home} = "$root";

	$app->log->debug("CMS: Posts folder is: $config->{cms_home}/posts");
	$app->log->debug("CMS: Prefix for cms pages is: " . ($config->{prefix}?$config->{prefix}:'/'));

	return $config;
}

sub open_file {
	my ($self, $filename) = @_;
	my $file;
	$file = eval {
		  my $fh;
		  local $/ = undef;
		  open $fh, '<:encoding(utf8)', $filename;
		  my $content = <$fh>;
		  close $fh;
		  $content;
	};
	return $file;
}

1;