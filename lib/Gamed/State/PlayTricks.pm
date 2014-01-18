package Gamed::State::PlayTricks;

use parent 'Gamed::State';

sub build {
    my ( $self, $logic ) = @_;
    $self->{logic} = $logic;
}

sub on_enter_state {
    my ( $self, $game ) = @_;
    $self->{active_player} = $game->{leader};
    $self->{trick}         = [];
}

sub on_message {
    my ( $self, $game, $client, $msg ) = @_;
    if ( $client->{in_game_id} != $self->{active_player} ) {
        $client->err('Not your turn');
        return;
    }

    my $seat = $game->{players}{ $self->{active_player} };
    if ( $self->{logic}
        ->is_valid_play( $msg->{play}, $self->{trick}, $seat->{cards}, $game ) )
    {
        push @{ $self->{trick} }, $msg->{play};
        $seat->{cards}->remove( $msg->{play} );
        $game->broadcast(
            { player => $self->{active_player}, play => $msg->{play} } );
        $self->{active_player}++;
        $self->{active_player} = 0
          if $self->{active_player} >= keys %{ $game->{players} };
        if ( @{ $self->{trick} } == keys %{ $game->{players} } ) {
            $self->{active_player}
              = $self->{logic}->trick_winner( $self->{trick}, $game )
              + $self->{active_player};
            $self->{active_player} -= keys %{ $game->{players} }
              if $self->{active_player} >= keys %{ $game->{players} };
            $game->broadcast(
                { trick => $self->{trick}, winner => $self->{active_player} } );
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
        $client->err('Invalid card');
    }
}

1;
