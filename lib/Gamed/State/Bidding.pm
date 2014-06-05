package Gamed::State::Bidding;

use Scalar::Util 'looks_like_number';

use Gamed::Handler;
use parent 'Gamed::State';

sub new {
    my ( $pkg, %opts ) = @_;
    my $self = bless \%opts, $pkg;
    $self->{starting_player} = 0;
    $self->{name} ||= 'Bidding';
    die "Missing next\n"  unless $self->{next};
    die "Missing min\n"   unless looks_like_number( $self->{min} );
    die "Missing max\n"   unless looks_like_number( $self->{max} );
    die "Missing valid\n" unless ref( $self->{valid} ) eq 'CODE';
	return $self;
}

sub on_enter_state {
    my ( $self, $game ) = @_;
    $self->{bidder} = $self->{starting_player};
    $self->{starting_player}++;
}

sub on_leave_state {
    my ( $self, $game ) = @_;
    for ( values %{ $game->{players} } ) {
        delete $_->{bid};
        delete $_->{pass};
    }
    $game->{bidder} = delete $self->{bidder};
    $game->{bid}    = delete $self->{bid};
    $game->broadcast( bid => { bid => $game->{bid}, bidder => $game->{bidder} } );
}

on 'bid' => sub {
    my ( $self, $player, $msg ) = @_;
    my $game = $self->{game};
    if ( $player->{in_game_id} ne $self->{bidder} ) {
        $player->err('Not your turn');
        return;
    }

    if ( $msg->{bid} eq 'pass' ) {
        $game->{players}{$player->{in_game_id}}{pass} = 1;
        $game->broadcast( bid => { bid => 'pass', player => $self->{bidder} } );
        $self->next_bidder($game);
    }
    elsif ( !looks_like_number( $msg->{bid} ) ) {
        $player->err('Invalid bid');
    }
    elsif ( defined $self->{min} && $msg->{bid} < $self->{min} ) {
        $player->err( 'Bidding starts at ' . $self->{min} );
    }
    elsif ( defined $self->{max} && $msg->{bid} > $self->{max} ) {
        $player->err( 'Max bid is ' . $self->{max} );
    }
    elsif ( defined $self->{valid} && !$self->{valid}( $msg->{bid} ) ) {
        $player->err('Invalid bid');
    }
    elsif ( defined $self->{bid} && $self->{bid} >= $msg->{bid} ) {
        $player->err('You must bid up or pass');
    }
    else {
        $self->{bid} = $msg->{bid};
        $game->broadcast( bid => { bid => $msg->{bid}, player => $self->{bidder} } );
        $self->next_bidder($game);
    }
};

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

1;
