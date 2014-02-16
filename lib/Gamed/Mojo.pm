#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;

use Mojolicious::Lite;
use Mojolicious::Sessions;
use Mojo::Server::Daemon;
use EV;
use AnyEvent;
use Mojo::IOLoop;
use File::Basename 'dirname';
use File::Spec::Functions 'catdir';
use File::Find;
use Gamed;
use Gamed::DB;

my $sessions = Mojolicious::Sessions->new;
$sessions->cookie_name('gamed');
$sessions->default_expiration(86400);

sub startup {
	my $self = shift;
	$self->home->parse( catdir( dirname(__FILE__), '..', 'Gamed' ), 'Gamed' );
	$self->static->paths->[0]   = $self->home->rel_dir('public');
	$self->renderer->paths->[0] = $self->home->rel_dir('templates');
}

post '/' => sub {
    my $self = shift;
	my $user = $self->login;
	if (defined $user) {
    	$self->session( 'username', $user->{username} );
    	$self->session( 'name', $user->{name} );
    	$self->session( 'avatar', $user->{avatar} );
    	$self->redirect_to('/');
	}
	else {
		$self->stash(error => 'Incorrect username or passphrase');
		$self->render('login');
	}
};

post '/newaccount' => sub {
	my $self = shift;
	my $user = $self->create_user;
	if (defined $user) {
    	$self->session( 'username', $user->{username} );
    	$self->session( 'name', $user->{name} );
    	$self->session( 'avatar', $user->{avatar} );
    	$self->redirect_to('/');
	}
	else {
		$self->render('login');
	}
};

group {
    under sub {
        my $self = shift;
        my $username = $self->session('username');
        if ( !defined $username ) {
            $self->render('login');
            return;
        }
        return 1;
    };

    get '/' => sub {
        my $self = shift;
        $self->render(
            'lobby',
            game  => 'Lobby',
            games => [ sort keys(%Gamed::games) ] );
    };

    get '/create/:game' => sub {
        my $self = shift;
        my $game = $self->param('game');
        if ( $Gamed::games{$game} ) {
            $self->render( "create-$game", game => $game );
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
            $self->stash( error => $@ );
            $self->render( "create-$game", game => $game );
        }
        else {
            $self->redirect_to( "/game/" . $self->param('name') );
        }
    };

    get '/game/:name' => sub {
        my $self = shift;
        my $name = $self->param('name');
        if ( exists $Gamed::game_instances{$name} ) {
            my $game = ( split( /::/, ref( $Gamed::game_instances{$name} ) ) )[-1];
            $self->render(
                "game-$game",
                game => $game,
                name => $name,
			 );
        }
        else {
            $self->stash( error => "No game named '$name' exists" );
            $self->redirect_to('/');
        }
    };

    websocket '/game/:name/websocket' => sub {
        my $self = shift;
        $self->app->log->debug('WebSocket connected.');
        Mojo::IOLoop->stream( $self->tx->connection )->timeout(3600);
        my $player = Gamed::Player->new( { name => $self->session('name'), sock => $self, id => $self->session('username'), avatar => $self->session('avatar') } );
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
                    Gamed::on_quit($player);
                    $self->app->log->debug('WebSocket disconnected.');
                } );
        }
    };
};

get '/flushcache' => sub {
    my $self = shift;
    $self->app->renderer->cache( Mojo::Cache->new );
    $self->render( text => "OK" );
};

my $daemon = Mojo::Server::Daemon->new( app => app, listen => ['http://*:8088'] );
$daemon->run;

AE::cv->recv;
