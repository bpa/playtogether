package Gamed::State::Bidding;

use Scalar::Util 'looks_like_number';

use Gamed::Handler;
use parent 'Gamed::State';

sub new {
    my ( $pkg, %opts ) = @_;
    my $self = bless \%opts, $pkg;
    $self->{bidder} = 0;
    $self->{name} ||= 'Bidding';
    die "Missing next\n"  unless $self->{next};
    die "Missing min\n"   unless looks_like_number( $self->{min} );
    die "Missing max\n"   unless looks_like_number( $self->{max} );
    die "Missing valid\n" unless ref( $self->{valid} ) eq 'CODE';
    return $self;
}

sub on_enter_state {
    my ( $self, $game ) = @_;
    $self->{seats}          = $game->{seats} || [ 0 .. scalar( keys %{ $game->{players} } ) - 1 ];
    $self->{bidder}         = ++$self->{bidder} % @{ $self->{seats} };
    $self->{current_bidder} = $self->{bidder};
    $game->{public}{bid}    = 0;
    $game->{public}{bidder} = $self->{seats}[ $self->{bidder} ];
    for ( values %{ $game->{players} } ) {
        delete $_->{public}{pass};
        delete $_->{public}{bid};
    }
    $game->broadcast( bidding => { bidder => $game->{public}{bidder}, min => $self->{min} } );
}

sub on_leave_state {
    my ( $self, $game ) = @_;
	$game->{public}{bid} = $self->{min} if $game->{public}{bid} < $self->{min};
	$game->{public}{player} = $game->{public}{bidder};
    $game->broadcast( bid => { bid => $game->{public}{bid}, bidder => $game->{public}{bidder} } );
}

on 'bid' => sub {
    my ( $self, $client, $msg, $player ) = @_;
    my $game = $self->{game};
    if ( $client->{in_game_id} ne $game->{public}{bidder} ) {
        $client->err('Not your turn');
        return;
    }

    if ( $msg->{bid} eq 'pass' ) {
        $player->{public}{pass} = 1;
        $self->next_bidder($game);
        $game->broadcast( bid => { bid => 'pass', player => $client->{in_game_id}, bidder => $game->{public}{bidder} } );
    }
    elsif ( !looks_like_number( $msg->{bid} ) ) {
        $client->err('Invalid bid');
    }
    elsif ( defined $self->{min} && $msg->{bid} < $self->{min} ) {
        $client->err( 'Bidding starts at ' . $self->{min} );
    }
    elsif ( defined $self->{max} && $msg->{bid} > $self->{max} ) {
        $client->err( 'Max bid is ' . $self->{max} );
    }
    elsif ( defined $self->{valid} && !$self->{valid}( $msg->{bid} ) ) {
        $client->err('Invalid bid');
    }
    elsif ( defined $game->{public}{bid} && $game->{public}{bid} >= $msg->{bid} ) {
        $client->err('You must bid up or pass');
    }
    else {
        $game->{public}{bid} = $msg->{bid};
        $player->{public}{bid} = $msg->{bid};
        $self->next_bidder($game);
        $game->broadcast( bid => { bid => $game->{public}{bid}, player => $client->{in_game_id}, bidder => $game->{public}{bidder} } );
    }
};

sub next_bidder {
    my ( $self, $game ) = @_;
    do {
        $self->{current_bidder} = ++$self->{current_bidder} % @{ $self->{seats} };
    } while defined $game->{players}{ $self->{seats}[$self->{current_bidder}] }{public}{pass};
    $game->{public}{bidder} = $self->{seats}[ $self->{current_bidder} ];

    if ( grep( !exists $_->{public}{pass}, values %{ $game->{players} } ) == 1 ) {
        $game->change_state( $self->{next} );
    }
}

1;
