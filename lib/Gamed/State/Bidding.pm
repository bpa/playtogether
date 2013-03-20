package Gamed::State::Bidding;

use Carp;
use parent 'Gamed::State';
use Scalar::Util 'looks_like_number';

sub build {
    my ( $self, $opts ) = @_;
    $self->{bidder} = 0;
    $self->{next}   = delete $opts->{next};
    $self->{min}    = delete $opts->{min};
    $self->{max}    = delete $opts->{max};
    $self->{valid}  = delete $opts->{valid};
    if ( %opts > 0 ) {
        croak 'Unknown options: ' . join( ',', keys %opts );
    }
}

sub on_message {
    my ( $self, $game, $client, $msg ) = @_;
    if ( $client->{id} ne $game->{players}[$self->{bidder}]{id} ) {
        $client->err('Not your turn');
        return;
    }
    my $seat = $game->{seat}[$self->{bidder}];
    if ( !defined $msg->{bid} ) {
        $client->err('No bid given');
    }
    elsif ( $msg->{bid} eq 'pass' ) {
        $seat->{pass} = 1;
        $game->broadcast( { bid => 'pass', player => $seat->{name} } );
        $self->next_bidder;
    }
    elsif ( !looks_like_number($msg->{bid}) ) {
        $client->err('Invalid bid');
    }
    elsif ( defined $self->{min} && $msg->{bid} < $self->{min} ) {
        $client->err( 'Bidding starts at ' . $self->{min} );
    }
    elsif ( defined $self->{max} && $msg->{bid} > $self->{max} ) {
        $client->err( 'Max bid is ' . $self->{max} );
    }
    elsif ( defined $self->{valid} && !$self->{valid}($msg->{bid})) {
        $client->err( 'Invalid bid');
    }
    else {
        $self->{current} = $msg->{bid};
        $game->broadcast( { bid => $msg->{bid}, player => $seat->{name} } );
        $self->next_bidder;
    }
}

sub on_leave_state {
    my ( $self, $game ) = @_;
    for ( @{ $game->{seat} } ) {
        delete $_->{bid};
        delete $_->{pass};
    }
    $game->{high_bidder} = delete $self->{high_bidder};
    $game->{bid}         = delete $self->{bid};
}

sub next_bidder {
    my ( $self, $game ) = @_;
    do {
        $self->{bidder}++;
        $self->{bidder} = 0 if $self->{bidder} == $game->{seats};
    } while defined $game->{seat}[$self->{bidder}]{pass};
}

1;
