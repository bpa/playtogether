package Gamed::State::FillSeats;

use strict;
use warnings;

use parent 'Gamed::State';

sub build {
    my ( $self, $players, $next_state ) = @_;
    $self->{max}        = $players;
    $self->{next_state} = $next_state;
}

sub on_join {
    my ( $self, $game, $player, $message ) = @_;
    push @{ $game->{players} }, $player;
    $game->change_state( $self->{next_state} )
      if ( @{ $game->{players} } >= $self->{max} );
}

1;
