package Gamed::State::Dealing;

use strict;
use warnings;
use Scalar::Util 'looks_like_number';
use Gamed::Object;

use parent 'Gamed::State';

sub build {
    my ( $self, $opts ) = @_;
    $self->{next} = $opts->{next};
    $self->{deck} = $opts->{deck};
    if ( looks_like_number( $opts->{deal} ) ) {
        $self->{deal} = { seat => $opts->{deal} };
    }
    else {
        $self->{deal} = $opts->{deal};
    }
    $self->{dealer} = 0;
}

sub on_enter_state {
    my ( $self, $game ) = @_;
    $game->broadcast( { dealing => $self->{dealer} } );
}

sub on_message {
    my ( $self, $game, $client, $msg ) = @_;
    if ( $client->{in_game_id} eq $self->{dealer} ) {
        $game->change_state( $self->{next} );
    }
    else {
        $client->err('Not your turn');
    }
}

sub on_leave_state {
    my ( $self, $game ) = @_;
    $self->{deck}->reset->shuffle;

    while ( my ( $k, $num ) = each( %{ $self->{deal} } ) ) {
        if ( $k eq 'seat' ) {
            my $seats = scalar( keys %{ $game->{players} }) - 1;
            for my $s ( 0 .. $seats ) {
                my $cards = bag( $self->{deck}->deal($num) );
                $game->{players}{$s}{cards} = $cards;
                $game->{players}{$s}{client}->send(
                    { cmd => 'game', action => 'deal', hand => [ $cards->values ] }
                );
            }
        }
        else {
            $game->{$k} = bag( $self->{deck}->deal($num) );
        }
    }
    $self->{dealer}++;
    $self->{dealer} = 0 if $self->{dealer} >= keys %{ $game->{players} };
    $game->{leader} = $self->{dealer};
}

1;
