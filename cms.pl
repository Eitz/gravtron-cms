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

app->config(
	hypnotoad => {listen => ['http://*:3000']}
);

helper dt => sub {
	return "DateTime";
};

helper find_categories => sub {
    my ($c) = @_;
    
    my $dir = "$POST_HOME";

    opendir(my $dh, $dir) or return undef;
    my @dirs = 
    			grep { -d "$POST_HOME/$_" && !/\..?/ } readdir($dh);
    closedir($dh);
    return @dirs;
};

helper find_posts => sub {
    my ($c, $categoria) = @_;
    
    my $dir = "$POST_HOME/$categoria";

    opendir(my $dh, $dir) or return undef;
    my @files = 
    			grep { /\.post$/ } readdir($dh);
    closedir($dh);
    return @files;
};

helper read_post => sub {
	my ($c, $filename, $extra) = @_;

	say $filename;

	my $file;
	{ my $fh;
	  local $/ = undef;
	  open $fh, '<:encoding(utf8)', $filename;
	  $file = <$fh>;
	  close $fh;
	}

	my %info;

	my ($info_text, $body) = split '↓↓↓', $file;
	for my $line (split '\n', $info_text){
		my ($key, $value) = split ':', $line;
		$key =~ s/^\s+//;
		$key =~ s/\s+$//;
		$value =~ s/^\s+//;
		$value =~ s/\s+$//;
		if ($key eq "date"){
			my @arr = split '-', $value;
			$value = DateTime->new(year => $arr[0], month => $arr[1], day => $arr[2], locale => "pt_BR");
		}
		$info{$key} = $value;
	}
	return \%info, $body;
};

get '/' => sub {
	my $c = shift;
	
	my @posts;
	my @categorias = $c->find_categories;

	for my $cat (@categorias){

		my $cat_path = "$POST_HOME/$cat";
		my @files = $c->find_posts($cat);
				
		for my $post (@files){

			my $post_path = "$cat_path/$post";

			my ($info, undef) = $c->read_post("$post_path");
			push @posts, $info;
		}
	}

	my @posts_sorted = sort{ $b->{date} cmp $a->{date} } @posts;

	$c->stash(posts => \@posts_sorted);
	$c->render('index');
};

get '/sobre';

post '/contato';

get '/artigos';

get '/artigos/:categoria/' => sub {
	my $c = shift;
	my $categoria = $c->param('categoria');

	my $cat_path = "$POST_HOME/$categoria";

	unless (-d $cat_path) {
		return $c->reply->not_found;
	}

	my @files = $c->find_posts($categoria);

	my @infos;
	for my $post (@files){
		my $post_path = "$cat_path/$post.post";
		my ($info, undef) = $c->read_post($post_path);
		push @infos, $info
	}

	return $c->render(text => "@infos");
};

get '/artigos/:categoria/:post' => sub {
	my $c = shift;
	
	my $categoria = $c->param('categoria');
	my $post = $c->param('post');

	my $cat_path = "$POST_HOME/$categoria";
	my $post_path = "$cat_path/$post.post";

	unless (-d $cat_path || -f $post_path) {
		return $c->reply->not_found
	}

    my ($info, $body) = $c->read_post($post_path);

	return $c->render(text => 'opa');
};

app->start;
