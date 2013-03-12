#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;

use Gamed;
use Mojolicious::Lite;
use Mojolicious::Sessions;
use Mojo::Server::Daemon;
use EV;
use AnyEvent;
use Mojo::IOLoop;
use File::Basename 'dirname';
use File::Spec::Functions 'catdir';
use File::Find;

my $sessions = Mojolicious::Sessions->new;
$sessions->cookie_name('gamed');
$sessions->default_expiration(86400);

get '/' => sub {
    my $self = shift;
    my $user = $self->session('user');
    my $game = $self->session('game');
    $self->app->log->debug("User: $user");
    $self->render(
        defined $user ? 'index' : 'login',
        user => $user,
        game => $game
    );
};

post '/login' => sub {
    my $self = shift;
    my $user = $self->param('username');
    if ( defined $user ) {
        $self->session( user => $user );
        $self->session( game => 'lobby' );
        $self->render( 'index', user => $user, game => 'lobby' );
    }
    else {
        $self->render('login');
    }
};

get '/lobby' => sub {
    my $self = shift;
    $self->render('lobby', games => [sort keys(%Gamed::games)]);
};

websocket '/websocket' => sub {
    my $self = shift;
    $self->app->log->debug('WebSocket connected.');
    Mojo::IOLoop->stream( $self->tx->connection )->timeout(3600);
	my $user = $self->session('user');
	my $id = Gamed::on_connect($user, $self);
	$self->app->log->debug($self);

    $self->on(
        message => sub {
            my ( $self, $msg ) = @_;
			$self->app->log->debug($msg);
			Gamed::on_message($id, $msg);
			$self->app->log->debug($self);
        }
    );

    $self->on(
        finish => sub {
            my $self = shift;
            $self->app->log->debug('WebSocket disconnected.');
			Gamed::on_disconnect($user);
        }
    );
};

my $daemon = Mojo::Server::Daemon->new( app => app, listen => ['http://*:8080'] );
$daemon->app->home->parse( catdir( dirname(__FILE__), '..', 'Gamed' ), 'Gamed');
$daemon->app->static->paths->[0]   = $daemon->app->home->rel_dir('public');
$daemon->app->renderer->paths->[0] = $daemon->app->home->rel_dir('templates');
$daemon->start;

AE::cv->recv;
