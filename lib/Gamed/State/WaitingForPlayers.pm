package Gamed::State::WaitingForPlayers;

use strict;
use warnings;

use parent 'Gamed::State';

sub build {
    my ( $self, $next ) = @_;
    $self->{next} = $next;
}

sub on_join {
    my ( $self, $game, $player ) = @_;
    push @{ $game->{players} }, $player;
    $player->{seat} = $#{$game->{players}};
    $game->{seat}[$player->{seat}]{id} = $player->{id};
    $game->change_state( $self->{next} )
      if @{ $game->{players} } >= @{$game->{seat}};
}

sub on_message {
    my ($self, $game, $player, $message) = @_;
    if ($message->{start} eq 'now') {
        $game->change_state( $self->{next} );
    }
}

1;
