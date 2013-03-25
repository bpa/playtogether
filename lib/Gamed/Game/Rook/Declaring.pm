package Gamed::Game::Rook::Declaring;

use strict;
use warnings;

use parent 'Gamed::State';

sub build {
    my ( $self, $next ) = @_;
    $self->{next} = $next;
}

sub on_message {
    my ( $self, $game, $client, $msg ) = @_;
    if ( $client->{id} eq $game->{players}[$game->{bidder}]{id} ) {
        $game->change_state( $self->{next} );
    }
    else {
        $client->send( { cmd => 'err', reason => 'Not your turn' } );
    }
}

1;
