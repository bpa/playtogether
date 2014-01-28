package Gamed::State::Bidding;

use Moose;
use Scalar::Util 'looks_like_number';
use namespace::autoclean;

extends 'Gamed::State';

has '+name' => ( default => 'Bidding' );
has 'next'  => ( is => 'ro', required => 1 );
has 'min'   => ( is => 'ro', required => 1 );
has 'max'   => ( is => 'ro', required => 1 );
has 'valid' => ( is => 'ro', required => 1 );

sub BUILD {
    my ( $self, $opts ) = @_;
    $self->{starting_player} = 0;
}

sub on_enter_state {
    my ( $self, $game ) = @_;
    $self->{bidder} = $self->{starting_player};
    $self->{starting_player}++;
}

sub on_message {
    my ( $self, $game, $player, $msg ) = @_;
    if ( $player->{in_game_id} ne $self->{bidder} ) {
        $player->{client}->err('Not your turn');
        return;
    }
    if ( !defined $msg->{bid} ) {
        $player->{client}->err('No bid given');
    }
    elsif ( $msg->{bid} eq 'pass' ) {
        $player->{pass} = 1;
        $game->broadcast( { bid => 'pass', player => $self->{bidder} } );
        $self->next_bidder($game);
    }
    elsif ( !looks_like_number( $msg->{bid} ) ) {
        $player->{client}->err('Invalid bid');
    }
    elsif ( defined $self->{min} && $msg->{bid} < $self->{min} ) {
        $player->{client}->err( 'Bidding starts at ' . $self->{min} );
    }
    elsif ( defined $self->{max} && $msg->{bid} > $self->{max} ) {
        $player->{client}->err( 'Max bid is ' . $self->{max} );
    }
    elsif ( defined $self->{valid} && !$self->{valid}( $msg->{bid} ) ) {
        $player->{client}->err('Invalid bid');
    }
    elsif ( defined $self->{bid} && $self->{bid} >= $msg->{bid} ) {
        $player->{client}->err('You must bid up or pass');
    }
    else {
        $self->{bid} = $msg->{bid};
        $game->broadcast( { bid => $msg->{bid}, player => $self->{bidder} } );
        $self->next_bidder($game);
    }
}

sub on_leave_state {
    my ( $self, $game ) = @_;
    for ( values %{ $game->{players} } ) {
        delete $_->{bid};
        delete $_->{pass};
    }
    $game->{bidder} = delete $self->{bidder};
    $game->{bid}    = delete $self->{bid};
    $game->broadcast( { bid => $game->{bid}, bidder => $game->{bidder} } );
}

sub next_bidder {
    my ( $self, $game ) = @_;
    do {
        $self->{bidder}++;
        $self->{bidder} = 0 if $self->{bidder} == keys %{ $game->{players} };
    } while defined $game->{players}{ $self->{bidder} }{pass};

    if ( grep( !exists $_->{pass}, values %{ $game->{players} } ) == 1 ) {
        $game->change_state( $self->{next} );
    }
}

__PACKAGE__->meta->make_immutable;
