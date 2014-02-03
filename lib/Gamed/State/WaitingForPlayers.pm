package Gamed::State::WaitingForPlayers;

use v5.14;
use Moose;
extends 'Gamed::State';
use namespace::autoclean;

has 'next' => (
    is       => 'ro',
    required => 1,
);

has '+name' => (
	default => 'WaitingForPlayers',
);

around 'BUILDARGS' => sub {
	my $orig = shift;
	my $class = shift;

    if ( @_ == 1 && !ref $_[0] ) {
        return $class->$orig( next => $_[0] );
    }
    else {
        return $class->$orig(@_);
    }
};

sub on_join {
    my ( $self, $game, $player ) = @_;
    my $players = grep { defined $_->{client} } values %{ $game->{players} };
    $game->change_state( $self->{next} )
      if $players >= $game->{max_players};
}

sub on_message {
    my ( $self, $game, $player, $message ) = @_;
    for ( $message->{cmd} ) {
        when ('ready') {
            if (  !defined( $game->{min_players} )
                || keys %{ $game->{players} } >= $game->{min_players} )
            {
                $player->{ready} = 1;
                $game->broadcast(
                    { cmd => 'ready', player => $player->{in_game_id} } );
                $game->change_state( $self->{next} )
                  unless keys %{ $game->{players} } < $game->{min_players}
                  || grep { !$_->{ready} } values %{ $game->{players} };
            }
            else {
                $player->{client}->err("Not enough players");
            }
        }
        when ('not ready') {
            $game->{players}{ $player->{in_game_id} }{ready} = 0;
            $game->broadcast(
                { cmd => 'not ready', player => $player->{in_game_id} } );
        }
        when ('theme') {
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

    if (  !defined( $game->{min_players} )
        || keys %{ $game->{players} } >= $game->{min_players} )
    {
        my $ready = 1;
        for my $p ( values %{ $game->{players} } ) {
            $ready = 0 unless $p->{ready};
        }
        if ($ready) {
            $game->change_state( $self->{next} );
        }
    }
}

__PACKAGE__->meta->make_immutable;
