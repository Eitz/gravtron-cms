#!/usr/bin/env perl

# This software is free. No warranties. 

################################################################################
#   ____                 _     _           _                                   #
#  / ___|_ __ __ ___   _(_) __| | __ _  __| | ___   Richard Eitz               #
# | |  _| '__/ _` \ \ / | |/ _` |/ _` |/ _` |/ _ \  richard.eitz@gravidade.org #
# | |_| | | | (_| |\ V /| | (_| | (_| | (_| |  __/                             #
#  \____|_|  \__,_| \_/ |_|\__,_|\__,_|\__,_|\___|  http://www.gravidade.org   #
#                                                                              #
################################################################################
use utf8;
use Mojolicious::Lite;
use FindBin;
use DateTime;

my $POST_HOME = "$FindBin::Bin/posts";
my $PREFIX = '';

get '/' => sub {
	my $c = shift;
	
	my @posts;
	my @categorias = $c->find_categories;

	for my $categoria (@categorias){

		my @files = $c->find_posts($categoria);
				
		for my $post (@files){

			my ($info, undef) = $c->read_post($categoria, $post);
			push @posts, $info;
		}
	}

	my @posts_sorted = sort{ $b->{date} cmp $a->{date} } @posts;

	$c->stash(posts => \@posts_sorted);
	$c->render('index');
};

get '/sobre';

post '/contato';

get '/sitemap' => [format => qw/txt/] => sub {
	my $c = shift;

	my $text = "http://gravidade.org/\n";

	my @categorias = $c->find_categories;

	for my $categoria (@categorias){

		$text .= "http://gravidade.org/$categoria\n";

		my @files = $c->find_posts($categoria);
				
		for my $post (@files){
			my ($info, undef) = $c->read_post($categoria, $post);
			$text .= "http://gravidade.org$info->{url}\n";
		}
	}

	return $c->render(text => $text);
};

if ($PREFIX){
	get "$PREFIX" => sub {
		shift->redirect_to('/');
	};
}

get "$PREFIX/:categoria/" => sub {
	my $c = shift;
	my $categoria = $c->param('categoria');

	my @posts;
	my @files = $c->find_posts($categoria);
	for my $post (@files){
		my ($info, undef) = $c->read_post($categoria, $post);
		if ($info){
			push @posts, $info;
		}
	}

	unless (@posts) {
		return $c->reply->not_found
	}

	my @posts_sorted = sort{ $b->{date} cmp $a->{date} } @posts;

	$c->stash(posts => \@posts_sorted, categoria => ucfirst $categoria);
	$c->render('category');
};

get "$PREFIX/:categoria/:post" => sub {
	my $c = shift;

	my $categoria = $c->param('categoria');
	my $post = $c->param('post');

	my ($info, $body) = $c->read_post($categoria, $post);

	unless ($info && $body) {
		return $c->reply->not_found
	}

	$c->stash(info => $info, body => $body);	
	return $c->render('post');
};



helper dt => sub {
	return "DateTime";
};

helper find_categories => sub {
    my ($c) = @_;
    
    my $dir = "$POST_HOME";

    opendir(my $dh, $dir) or return undef;
    my @dirs = grep { -d "$POST_HOME/$_" && !/\..?/ } readdir($dh);
    closedir($dh);
    return @dirs;
};

helper find_posts => sub {
    my ($c, $categoria) = @_;
    
    my $dir = "$POST_HOME/$categoria";

    opendir(my $dh, $dir) or return undef;
    my @files = 
    			map { s/\.post//; $_ }
    			grep { /\.post$/ } readdir($dh);
    closedir($dh);
    return @files;
};

helper read_post => sub {
	my ($c, $categoria, $post, $extra) = @_;

	my $filename = "$POST_HOME/$categoria/$post.post";
	my $file = $c->open_file($filename);

	unless ($file) {
		return undef, undef;
	}

	my ($info_text, $body) = split '↓↓↓', $file;

	my $info = {
		categoria => $categoria,
		post_slug => $post,
		url => "$PREFIX/$categoria/$post"
	};
	
	for my $line (split '\n', $info_text){

		my ($key, $value) = split '=>', $line;
		
		$key =~ s/^\s+//; $key =~ s/\s+$//;
		$value =~ s/^\s+//; $value =~ s/\s+$//;

		if ($key eq 'date'){
			my @arr = split '-', $value;
			$value = eval{ 
						$c->dt->new(
							year 	=> $arr[0],
							month 	=> $arr[1],
							day 	=> $arr[2],
							locale 	=> "pt_BR"
						)
		 			};
		}
		$info->{$key} = $value;
	}

	
	return $info, $body;
};

helper open_file => sub {
	my ($c, $filename) = @_;
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

app->config(
	hypnotoad => {listen => ['http://*:3000']}
);

app->start;