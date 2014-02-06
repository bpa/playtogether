package Gamed::State::WaitingForPlayers;

use v5.14;
use Moose;
extends 'Gamed::State';
use namespace::autoclean;

has 'next' => ( is => 'ro', required => 1 );
has '+name' => ( default => 'WaitingForPlayers' );

sub on_enter_state {
    my ( $self, $game ) = @_;
    if ( defined $game->{seats} ) {
        $self->{available} = $game->{seats};
    }
    $self->{min} = $game->{min_players} || scalar( @{ $game->{seats} } );
    $self->{max} = $game->{max_players} || scalar( @{ $game->{seats} } );
}

sub on_join {
    my ( $self, $game, $player ) = @_;
	if (defined $self->{available}) {
		my $id = shift @{$self->{available}};
		$game->{ids}{$player->{client}{id}} = $id;
		$game->{players}{$id} = delete $game->{players}{$player->{in_game_id}};
		$player->{in_game_id} = $id;
		$player->{client}{in_game_id} = $id;
	}
    my $players = grep { defined $_->{client} } values %{ $game->{players} };
    $game->change_state( $self->{next} )
      if $players >= $self->{max};
}

sub on_message {
    my ( $self, $game, $player, $message ) = @_;
    for ( $message->{cmd} ) {
        when ('ready') {
            if ( keys %{ $game->{players} } >= $game->{min_players} ) {
                $player->{ready} = 1;
                $game->broadcast( { cmd => 'ready', player => $player->{in_game_id} } );
                $game->change_state( $self->{next} )
                  unless grep { !$_->{ready} } values %{ $game->{players} };
            }
            else {
                $player->{client}->err("Not enough players");
            }
        }
        when ('not ready') {
            $game->{players}{ $player->{in_game_id} }{ready} = 0;
            $game->broadcast( { cmd => 'not ready', player => $player->{in_game_id} } );
        }
        default {
            $player->{client}->err("Invalid command");
        }
    }
}

sub on_quit {
    my ( $self, $game, $player ) = @_;
    delete $game->{players}{ $player->{in_game_id} };
    delete $game->{ids}{ $player->{client_id} };
	if (defined($self->{available})) {
		unshift @{$self->{available}}, $player->{in_game_id};
	}

    if ( keys %{ $game->{players} } >= $self->{min} ) {
        $game->change_state( $self->{next} )
          unless grep { !$_->{ready} } values %{ $game->{players} };
    }
}

__PACKAGE__->meta->make_immutable;
