#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;

use Data::UUID;
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
use Module::Refresh;

my $uuid     = Data::UUID->new;
my $sessions = Mojolicious::Sessions->new;
$sessions->cookie_name('gamed');
$sessions->default_expiration(86400);

get '/' => sub {
    my $self = shift;
    my $user = $self->session('user');
    if ( defined $user ) {
        $self->render( 'lobby', user => $user, game => 'Lobby', games => [ sort keys(%Gamed::games) ] );
    }
    else {
        $self->render('login');
    }
};

post '/' => sub {
    my $self = shift;
    my $user = $self->param('username');
    if ( defined $user ) {
        $self->session( 'user', $user );
        $self->session( 'id',   $uuid->create_b64 );
        return $self->redirect_to('/');
    }
    else {
        $self->render('login');
    }
};

get '/create/:game' => sub {
    my $self = shift;
    my $game = $self->param('game');
    if ( $Gamed::games{$game} ) {
        $self->render("create-$game", game => $game);
    }
    else {
        $self->stash( error => "No game named '$game' exists" );
        $self->redirect_to('/');
    }
};

post '/create/:game' => sub {
	my $self = shift;
	my $game = $self->param('game');
	eval {
		my $opts = $self->req->params->to_hash;
		$opts->{game} = $game;
		Gamed::on_create($opts);
	};
	if ($@) {
		$self->stash(error => $@);
		$self->render("create-$game", game => $game);
	}
	else {
		$self->redirect_to("/game/".$self->param('name'));
	}
};

get '/game/:name' => sub {
    my $self = shift;
	my $name = $self->param('name');
	if (exists $Gamed::game_instances{$name}) {
		my $game = (split(/::/,ref($Gamed::game_instances{$name})))[-1];
    	$self->render($game, game => $game, name => $name, user => $self->session('user'));
	}
	else {
		$self->stash(error => "No game named '$name' exists");
		$self->redirect_to('/');
	}
};

websocket '/game/:name/websocket' => sub {
    my $self = shift;
    $self->app->log->debug('WebSocket connected.');
    Mojo::IOLoop->stream( $self->tx->connection )->timeout(3600);
    my $user = $self->session('user');
    my $player = Gamed::Player->new( { name => $user, sock => $self, id => $self->session('id') } );
    eval { Gamed::on_join( $player, $self->param('name') ); };
    if ($@) {
        $self->send("{'error':'$@'}");
        $self->finish;
    }
    else {
        $self->on(
            message => sub {
                my ( $self, $msg ) = @_;
                Gamed::on_message( $player, $msg );
            } );

        $self->on(
            finish => sub {
                my $self = shift;
                $self->app->log->debug('WebSocket disconnected.');
            } );
    }
};

get '/refresh/*module' => sub {
    my $self = shift;
    Module::Refresh->refresh($self->param('module'));
    $self->render(text => 'OK');
};

get '/flushcache' => sub {
    my $self = shift;
    $self->app->renderer->cache(Mojo::Cache->new);
    $self->render(text => "OK");
};

my $daemon = Mojo::Server::Daemon->new( app => app, listen => ['http://*:8080'] );
$daemon->app->home->parse( catdir( dirname(__FILE__), '..', 'Gamed' ), 'Gamed' );
$daemon->app->static->paths->[0]   = $daemon->app->home->rel_dir('public');
$daemon->app->renderer->paths->[0] = $daemon->app->home->rel_dir('templates');
$daemon->start;

AE::cv->recv;
