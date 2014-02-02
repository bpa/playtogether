package Gamed::Game::SpeedRisk::Playing;

use v5.14;
use Moose;
use namespace::autoclean;

extends 'Gamed::State';

has '+name' => ( default => 'Playing' );
has 'next' => ( default => 'GAME_OVER', is => 'bare' );

sub on_enter_state {
    my ( $self, $game ) = @_;
    $game->broadcast( { cmd => 'state', state => 'Playing' } );
	#TODO: set timer
}

sub on_message {
    my ( $self, $game, $player, $message ) = @_;
    for ( $message->{cmd} ) {
		default {
			$player->{client}->err('Invalid command');
		}
    }
}

sub on_leave_state {
	#TODO: cancel timer
}

__PACKAGE__->meta->make_immutable;
