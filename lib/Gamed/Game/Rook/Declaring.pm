package Gamed::Game::Rook::Declaring;

use strict;
use warnings;

use parent 'Gamed::State';

sub build {
    my ( $self, $next ) = @_;
    $self->{next} = $next;
}

sub on_enter_state {
    my ( $self, $game ) = @_;
    $game->{players}[$game->{bidder}]->send( { nest => $game->{nest} } );
}

sub on_message {
    my ( $self, $game, $client, $msg ) = @_;
    if ( $client->{id} eq $game->{players}[$game->{bidder}]{id} ) {
        if ($msg->{trump} !~ /^[RGBY]$/) {
            $client->send( { cmd => 'error', reason => "'" . $msg->{trump} . "' is not a valid trump" } );
        }
        elsif (!defined $msg->{nest} || @{$msg->{nest}} != 5) {
            $client->send( { cmd => 'error', reason => 'Invalid nest' } );
        }
        else {
        }
    }
    else {
        $client->send( { cmd => 'error', reason => 'Not your turn' } );
    }
}

1;
