package Graviton::CMS::Category;
use Mojo::Base -base;

use Graviton::Util;

has 'name';
has 'posts';

sub slug {
	my $self = shift;
	return Graviton::Util->slugfy($self->name);
}

1;