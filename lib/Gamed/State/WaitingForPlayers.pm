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
            if (  !defined( $game->{min_players} )
                || keys %{ $game->{players} } >= $game->{min_players} )
            {
                $game->{players}{ $client->{in_game_id} }{ready} = 1;
                $game->broadcast(
                    { cmd => 'ready', player => $client->{in_game_id} } );
                $game->change_state( $self->{next} )
                  unless keys %{ $game->{players} } < $game->{min_players}
                  || grep { !$_->{ready} } values %{ $game->{players} };
            }
            else {
                $client->err("Not enough players");
            }
        }
        when ('not ready') {
            $game->{players}{ $client->{in_game_id} }{ready} = 0;
            $game->broadcast(
                { cmd => 'not ready', player => $client->{in_game_id} } );
        }
    }
}

sub on_quit {
    my ( $self, $game, $client ) = @_;
    delete $game->{players}{ $client->{in_game_id} };
    delete $game->{ids}{ $client->{id} };

    my $ready = 1;
    for my $p ( values %{ $game->{players} } ) {
        $ready = 0 unless $p->{ready};
    }
    if ($ready) {
        $game->broadcast( { cmd => 'ready', player => $client->{in_game_id} } );
        $game->change_state( $self->{next} );
    }
}

1;
