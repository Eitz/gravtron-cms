package CMS::Gravitron;
use FindBin;
use DateTime;

use Mojo::Base 'Mojolicious::Plugin';

has 'config';

sub register {
	my ($self, $app) = @_;

	$app->log->debug("CMS: Plugin loading started");

	# config
	my $config = $self->_config($app);
	$self->config($config);
	
	my $prefix = $self->config->{prefix};
	my $home = $self->config->{post_home};

	# static serve
	push @{$app->static->paths}, "$home/assets";

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
	
	$r->get("/" => sub { _index(shift, $self) } )->name("cms_root");
	$r->get("/:categoria/" => sub { _category(shift, $self)})->name("cms_category");
	$r->get("/:categoria/:post" => sub { _post(shift, $self)})->name("cms_post");

	# helpers
	$app->helper(cms => sub { _cms_helper(shift, $self, @_)});

	$app->log->debug("CMS: Loading complete");
}

sub _cms_helper {
	my $c = shift;
	my $self = shift;

	return CMS::Helpers->new( context => $self );
};

sub _config {
	my ($self, $app) = @_;

	my $root = "$FindBin::Bin/CMS";

	my $filename = "$root/cms.config";

	my $config = $self->_open_file($filename);

	$config = eval { eval "$config" };

	if ($config && defined $config->{post_home} && defined $config->{prefix}){
		
		$config->{post_home} = "$root/$config->{post_home}";
		$config->{post_home} =~ s|\/\/|\/|g;

		$config->{prefix} = "$config->{prefix}";
		$config->{prefix} =~ s|\/\/|\/|g;

	} else {
		$app->log->error("Problem loading config file('cms.config'): ".
						 "It has to be in the same folder as CMS.pm ".
						 "and it must have 'post_home' and 'prefix'.");
		$config = {
			prefix => '/blog',
			post_home => "$root/posts"
		};
	}

	$app->log->debug("CMS: Posts folder is: $config->{post_home}");
	$app->log->debug("CMS: Prefix for cms pages is: " . ($config->{prefix}?$config->{prefix}:'/'));

	return $config;
}


sub _index {
	my ($c, $self) = @_;

	my @posts;
	my @categorias = $self->_find_categories;

	for my $categoria (@categorias){

		my @files = $self->_find_posts($categoria);
				
		for my $post (@files){

			my $post = $self->_read_post($categoria, $post);
			if ($post){
				push @posts, $post;	
			}			
		}
	}

	my @posts_sorted = sort{ $b->{date} cmp $a->{date} } @posts;

	$c->stash(posts => \@posts_sorted);
	say @{$c->app->renderer->paths};
	return $c->render('cms_index.html.ep');
}

sub _category {
	my ($c, $self) = @_;
	my $categoria = $c->param('categoria');

	my @posts;
	my @files = $self->_find_posts($categoria);
	for my $file (@files){
		my $post = $self->_read_post($categoria, $file);
		if ($post){
			push @posts, $post;
		}
	}

	unless (@posts) {
		return $c->reply->not_found
	}

	my @posts_sorted = sort{ $b->{date} cmp $a->{date} } @posts;

	$c->stash(posts => \@posts_sorted, categoria => ucfirst $categoria);
	$c->render('cms_category');
}

sub _post {
	my ($c, $self) = @_;

	my $categoria = $c->param('categoria');
	my $post_slug = $c->param('post');

	my $post = $self->_read_post($categoria, $post_slug);

	unless ($post) {
		return $c->reply->not_found
	}

	$c->stash(post => $post);	
	return $c->render('cms_post');
}


sub _find_categories {
    my ($self) = @_;

    my $home = $self->config->{post_home};

    opendir(my $dh, $home) or return undef;
    my @dirs = grep { -d "$home/$_" && !/\..?/ && !/assets/ } readdir($dh);
    closedir($dh);
    return @dirs;
};

sub _find_posts {
    my ($self, $categoria) = @_;

    my $home = $self->config->{post_home};
    
    my $dir = "$home/$categoria";

    opendir(my $dh, $dir) or return undef;
    my @files = 
    			map { s/\.post//; $_ }
    			grep { /\.post$/ } readdir($dh);
    closedir($dh);
    return @files;
};

sub _read_post {
	my ($self, $categoria, $post_slug, $extra) = @_;

	my $home = $self->config->{post_home};
	my $prefix = $self->config->{prefix};

	my $filename = "$home/$categoria/$post_slug.post";
	my $file = $self->_open_file($filename);

	unless ($file) {
		return undef, undef;
	}

	my ($info_text, $body) = split '↓↓↓', $file;

	my $info = {
		categoria => $categoria,
		post_slug => $post_slug,
		url => "$prefix/$categoria/$post_slug"
	};
	
	for my $line (split '\n', $info_text){

		my ($key, $value) = split '=>', $line;
		
		$key =~ s/^\s+//; $key =~ s/\s+$//;
		$value =~ s/^\s+//; $value =~ s/\s+$//;

		if ($key eq 'date'){
			my @arr = split '-', $value;
			$value = eval{ 
						DateTime->new(
							year 	=> $arr[0],
							month 	=> $arr[1],
							day 	=> $arr[2],
							locale 	=> "pt_BR"
						)
		 			};
		}
		$info->{$key} = $value;
	}

	my $post = $info;
	if ($body){
		$post->{body} = $body;
	}
	
	return $post;
};

sub _open_file {
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
};



1;

package CMS::Helpers;
use Mojo::Base -base;

has 'context';

sub random_post {
	my $self = shift;

	my @categories = $self->context->_find_categories;
	my $cat = $categories[int(rand @categories)];

	my @posts = $self->context->_find_posts($cat);
	my $post_slug = $posts[int(rand @posts)];

	my $post = $self->context->_read_post($cat, $post_slug);

	return $post;
}

sub last_post {
	return {};
}

sub sitemap {
	my $self = shift;
	my $base = shift;
	use Data::Dumper;
	say Dumper($base);

	my $text = "$base/\n";

	my @categorias = $self->context->_find_categories;

	for my $categoria (@categorias){

		$text .= "$base/$categoria/\n";

		my @files = $self->context->_find_posts($categoria);
				
		for my $post (@files){
			my ($info, undef) = $self->context->_read_post($categoria, $post);
			if ($info){
				$text .= "$base$info->{url}/\n";
			}
		}
	}

	return $text;
}

1;