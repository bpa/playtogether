package Gamed::Game::Rook::Declaring;

use strict;
use warnings;

use parent 'Gamed::State';
use Gamed::Util;

sub build {
    my ( $self, $next ) = @_;
    $self->{next} = $next;
}

sub on_enter_state {
    my ( $self, $game ) = @_;
    $game->{players}[ $game->{bidder} ]->send( { nest => $game->{nest} } );
    push @{ $game->{seat}[ $game->{bidder} ]{cards} }, @{ $game->{nest} };
    delete $game->{nest};
}

sub on_message {
    my ( $self, $game, $client, $msg ) = @_;
    my $b    = $game->{bidder};
    my $seat = $game->{seat}[$b];
    if ( $client->{id} ne $game->{players}[$b]{id} ) {
        $client->send( { cmd => 'error', reason => 'Not your turn' } );
        return;
    }

    my $cards = bag(@{$seat->{cards}});
    my $nest = bag(@{$msg->{nest}});
    if ( $msg->{trump} !~ /^[RGBY]$/ ) {
        $client->send( { cmd => 'error', reason => "'" . $msg->{trump} . "' is not a valid trump" } );
    }
    elsif (!defined $msg->{nest}
        || @{ $msg->{nest} } != 5
        || !$nest->subset( $cards ) )
    {
        $client->send( { cmd => 'error', reason => 'Invalid nest' } );
    }
    else {
		$game->{trump} = $msg->{trump};
        $game->{nest} = $msg->{nest};
        my $hand = $cards - $nest;
        $seat->{cards} = [$hand->values];
		$game->broadcast( { trump => $game->{trump} } );
		$game->change_state($self->{next});
    }
}

1;
