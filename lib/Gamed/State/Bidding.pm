package Gamed::State::Bidding;

use Carp;
use parent 'Gamed::State';
use Scalar::Util 'looks_like_number';

sub build {
    my ( $self, $opts ) = @_;
	$self->{starting_player} = 0;
    $self->{next}   = delete $opts->{next};
    $self->{min}    = delete $opts->{min};
    $self->{max}    = delete $opts->{max};
    $self->{valid}  = delete $opts->{valid};
    if ( %opts > 0 ) {
        croak 'Unknown options: ' . join( ',', keys %opts );
    }
}

sub on_enter_state {
	my ($self, $game) = @_;
	delete $self->{seat};
	map { push @{$self->{seat}}, { name => $_->{name} }} @{$game->{seat}};
	$self->{bidder} = $self->{starting_player};
	$self->{starting_player}++;
}

sub on_message {
    my ( $self, $game, $client, $msg ) = @_;
    if ( $client->{id} ne $game->{players}[ $self->{bidder} ]{id} ) {
        $client->err('Not your turn');
        return;
    }
    my $seat = $self->{seat}[ $self->{bidder} ];
    if ( !defined $msg->{bid} ) {
        $client->err('No bid given');
    }
    elsif ( $msg->{bid} eq 'pass' ) {
        $seat->{pass} = 1;
        $game->broadcast( { bid => 'pass', player => $self->{bidder} } );
        $self->next_bidder($game);
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
    elsif ( defined $self->{bid} && $self->{bid} >= $msg->{bid} ) {
        $client->err('You must bid up or pass');
    }
    else {
        $self->{bid} = $msg->{bid};
        $game->broadcast( { bid => $msg->{bid}, player => $self->{bidder} } );
        $self->next_bidder($game);
    }
}

sub on_leave_state {
    my ( $self, $game ) = @_;
    for ( @{ $self->{seat} } ) {
        delete $_->{bid};
        delete $_->{pass};
    }
    $game->{bidder} = delete $self->{bidder};
    $game->{bid}    = delete $self->{bid};
	$game->broadcast( { bid => $game->{bid}, bidder => $game->{seat}[$game->{bidder}]{name} } );
}

sub next_bidder {
    my ( $self, $game ) = @_;
    do {
        $self->{bidder}++;
        $self->{bidder} = 0 if $self->{bidder} == @{$game->{seat}};
    } while defined $self->{seat}[ $self->{bidder} ]{pass};

    if ( grep(!exists $_->{pass}, @{$self->{seat}}) == 1) {
        $game->change_state( $self->{next} );
    }
}

1;
