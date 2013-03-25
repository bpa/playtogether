package Gamed::State::WaitingForPlayers;

use strict;
use warnings;

use parent 'Gamed::State';

sub build {
    my ( $self, $next ) = @_;
    $self->{next} = $next;
}

sub on_join {
    my ( $self, $game, $player, $message ) = @_;
    push @{ $game->{players} }, $player;
    $game->change_state( $self->{next} )
      if @{ $game->{players} } >= @{$game->{seat}};
}

1;
