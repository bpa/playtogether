package Gamed::State::GameOver;

use Moose;
use namespace::autoclean;

extends 'Gamed::State';

has '+name' => ( default => 'GameOver' );

sub on_enter_state {
    my ( $self, $game ) = @_;
    #TODO: set timer to destroy game
}

sub on_message {
    my ( $self, $game, $player, $msg ) = @_;
	$player->err('Invalid command');
}

__PACKAGE__->meta->make_immutable;
