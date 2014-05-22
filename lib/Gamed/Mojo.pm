#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;

use Mojolicious::Lite;
use Mojo::Server::Daemon;
use EV;
use AnyEvent;
use Mojo::IOLoop;
use File::Basename 'dirname';
use File::Spec::Functions 'catdir';
use Gamed;

websocket '/websocket' => sub {
	my $self = shift;
	$self->app->log->debug('WebSocket connected.');
	Mojo::IOLoop->stream( $self->tx->connection )->timeout(3600);
	my $player = Gamed::Player->new( { sock => $self } );
	if ($@) {
		$self->send('{"cmd":"error","reason":"'.$@.'"}');
		$self->finish;
	}
	else {
		$self->send('{"cmd":"login"}');
		$self->on(
			message => sub {
				my ( $self, $msg ) = @_;
				eval {
					Gamed::on_message( $player, $msg );
				};
				$player->err($@) if $@;
			} );

		$self->on(
			finish => sub {
				my $self = shift;
				Gamed::on_quit($player);
				$self->app->log->debug('WebSocket disconnected.');
			} );
	}
};

my $daemon = Mojo::Server::Daemon->new( app => app, listen => ['http://*:3000'] );
$daemon->app->home->parse( catdir( dirname(__FILE__), '..', 'Gamed' ), 'Gamed' );
$daemon->app->static->paths->[0]   = $daemon->app->home->rel_dir('public');
$daemon->app->renderer->paths->[0] = $daemon->app->home->rel_dir('public');
$daemon->run;

AE::cv->recv;
