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
use DateTime;

app->config(
		hypnotoad => {listen => ['http://*:3000']}
);

helper dt => sub {
	return "DateTime";
};

get '/' => 'index';

get '/sobre';

get '/artigos/:categoria/:titulo';

post '/contato';

get '/:catchall' => sub {
	return shift->render(text => "404 - under the influence")
;};

app->start;
