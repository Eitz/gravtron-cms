package Graviton::CMS::CMSController;
use Mojo::Base 'Mojolicious::Controller';

sub index {
	my $c = shift;

	my @posts;
	my @categorias = $c->cms->persistence->find_categories;

	for my $categoria (@categorias){

		my @files = $c->cms->persistence->find_posts($categoria);
				
		for my $post (@files){

			my $post = $c->cms->persistence->read_post($categoria, $post);
			if ($post){
				push @posts, $post;	
			}			
		}
	}

	my @posts_sorted = sort{ $b->{date} cmp $a->{date} } @posts;

	$c->stash(posts => \@posts_sorted);
	return $c->render( template => 'cms_index');
}

sub category {
	my ($c, $self) = @_;
	my $categoria = $c->param('categoria');

	my @posts;
	my @files = $c->cms->persistence->find_posts($categoria);
	for my $file (@files){
		my $post = $c->cms->persistence->read_post($categoria, $file);
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

sub post {
	my ($c, $self) = @_;

	my $categoria = $c->param('categoria');
	my $post_slug = $c->param('post');

	my $post = $c->cms->persistence->read_post($categoria, $post_slug);

	unless ($post) {
		return $c->reply->not_found
	}

	$c->stash(post => $post);	
	return $c->render('cms_post');
}

1;