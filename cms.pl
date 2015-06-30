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

use Mojolicious::Lite;

get '/sobre';

get '/contato' => sub {
	my $c = shift;
	$c->redirect_to('/#contato');
};

post '/contato' => sub {
	my $c = shift;

	my $nome	 = $c->param('nome');
	my $email	 = $c->param('email');
	my $mensagem = $c->param('mensagem');

	use Mojo::UserAgent;
	my $ua = Mojo::UserAgent->new;
	$ua->post('https://docs.google.com/forms/d/1tDSqZw90fHB1cmXpjSdVcFjZtoGthT-5ynBVbNWmeW0/formResponse' => 
			form => {
				'entry.1292260307' => $nome,
				'entry.1181439329' => $email,
				'entry.40411107' => $mensagem,
			}
	);
	
	my $post = $c->cms->random_post;

	$c->stash(post => $post);
	$c->render('cms/message_received');
};

get '/sitemap' => [format => qw/txt/] => sub {
	my $c = shift;

	my $text = $c->cms->sitemap("http://gravidade.org");

	return $c->render(text => $text);
};

plugin 'CMS';

app->config(
	hypnotoad => {listen => ['http://*:3000']},
);

app->log->level('info');
app->start;