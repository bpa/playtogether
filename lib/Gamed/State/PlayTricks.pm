package Gamed::State::PlayTricks;

use Moose;
use namespace::autoclean;

extends 'Gamed::State';

has '+name' => ( default => 'PlayTricks' );
has 'logic' => ( is => 'ro', required => 1 );

sub on_enter_state {
    my ( $self, $game ) = @_;
    $self->{active_player} = $game->{leader};
    $self->{trick}         = [];
}

sub on_message {
    my ( $self, $game, $player, $msg ) = @_;
    if ( $player->{in_game_id} != $self->{active_player} ) {
        $player->{client}->err('Not your turn');
        return;
    }

    if ( $self->{logic}
        ->is_valid_play( $msg->{play}, $self->{trick}, $player->{cards}, $game ) )
    {
        push @{ $self->{trick} }, $msg->{play};
        $player->{cards}->remove( $msg->{play} );
        $game->broadcast( play => { player => $self->{active_player}, play => $msg->{play} } );
        $self->{active_player}++;
        $self->{active_player} = 0
          if $self->{active_player} >= keys %{ $game->{players} };
        if ( @{ $self->{trick} } == keys %{ $game->{players} } ) {
            $self->{active_player}
              = $self->{logic}->trick_winner( $self->{trick}, $game )
              + $self->{active_player};
            $self->{active_player} -= keys %{ $game->{players} }
              if $self->{active_player} >= keys %{ $game->{players} };
            $game->broadcast( trick => { trick => $self->{trick}, winner => $self->{active_player} } );
            push @{ $game->{players}{ $self->{active_player} }{taken} },
              @{ $self->{trick} };
            $self->{trick} = [];
            if (grep ( scalar( $_->{cards}->values ), values %{ $game->{players} } )
                == 0 )
            {
                $self->{logic}->on_round_end($game);
            }
        }
    }
    else {
        $player->{client}->err('Invalid card');
    }
}

__PACKAGE__->meta->make_immutable;
