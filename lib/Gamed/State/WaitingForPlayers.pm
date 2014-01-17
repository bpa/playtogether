package Gamed::State::WaitingForPlayers;

use v5.14;
use strict;
use warnings;

use parent 'Gamed::State';

sub build {
    my ( $self, $next ) = @_;
    $self->{next} = $next;
}

sub on_join {
    my ( $self, $game, $client ) = @_;
	my $players = grep { defined $_->{client} } values %{ $game->{players} };
    $game->change_state( $self->{next} )
      if $players >= $game->{max_players};
}

sub on_message {
    my ( $self, $game, $client, $message ) = @_;
    for ( $message->{cmd} ) {
        when ('ready') {
            $game->change_state( $self->{next} )
              unless @{ $game->{players} } < $game->{min_players}
              || grep { !$_->{ready} } @{ $game->{players} };
        }
        when ('not ready') { $game->{players}{ $client->{id} }{ready} = 0; }
    }
}

1;
