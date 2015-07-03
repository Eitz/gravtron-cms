package Gravtron::CMS::Helpers;
use Mojo::Base -base;

has 'persistence';

sub random_post {
	my $self = shift;

	my @categories = $self->persistence->find_categories;
	my $cat = $categories[int(rand @categories)];

	my @posts = $self->persistence->find_posts($cat);
	my $post_slug = $posts[int(rand @posts)];

	my $post = $self->persistence->read_post($cat, $post_slug);

	return $post;
}

sub last_post {
	return {};
}

sub sitemap {
	my $self = shift;
	my $base = shift;

	my $text = "$base/\n";

	my @categorias = $self->persistence->find_categories;

	for my $categoria (@categorias){

		$text .= "$base/$categoria/\n";

		my @files = $self->persistence->find_posts($categoria);
				
		for my $post (@files){
			my ($info, undef) = $self->persistence->read_post($categoria, $post);
			if ($info){
				$text .= "$base$info->{url}/\n";
			}
		}
	}

	return $text;
}

1;