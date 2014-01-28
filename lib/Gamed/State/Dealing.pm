package Gamed::State::Dealing;

use Moose;
use Scalar::Util 'looks_like_number';
use Gamed::Object;

extends 'Gamed::State';

has '+name' => ( default => 'Dealing' );
has 'next' => ( is => 'ro', required => 1 );
has 'deck' => ( is => 'ro', required => 1 );

sub BUILD {
    my ( $self, $opts ) = @_;
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
    my ( $self, $game, $player, $msg ) = @_;
    if ( $player->{in_game_id} eq $self->{dealer} ) {
        $game->change_state( $self->{next} );
    }
    else {
        $player->{client}->err('Not your turn');
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

__PACKAGE__->meta->make_immutable;
