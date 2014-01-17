package Gamed::Game::Rook::Declaring;

use strict;
use warnings;

use parent 'Gamed::State';
use Gamed::Object;

sub build {
    my ( $self, $next ) = @_;
    $self->{next} = $next;
}

sub on_enter_state {
    my ( $self, $game ) = @_;
    $game->{players}{ $game->{bidder} }{client}->send( { nest => $game->{nest} } );
    $game->{players}{ $game->{bidder} }{cards}->add($game->{nest});
    delete $game->{nest};
}

sub on_message {
    my ( $self, $game, $client, $msg ) = @_;
    my $seat = $game->{players}{$game->{bidder}};
    if ( $client->{id} ne $game->{bidder} ) {
        $client->err( 'Not your turn' );
        return;
    }

    my $cards = bag($seat->{cards});
    my $nest = bag($msg->{nest});
    if ( $msg->{trump} !~ /^[RGBY]$/ ) {
        $client->err( "'" . $msg->{trump} . "' is not a valid trump" );
    }
    elsif (!defined $msg->{nest}
        || @{ $msg->{nest} } != 5
        || !$nest->subset( $cards ) )
    {
        $client->err( 'Invalid nest' );
    }
    else {
		$game->{trump} = $msg->{trump};
        $game->{nest} = bag($msg->{nest});
        my $hand = $cards - $nest;
        $seat->{cards} = $hand;
		$game->broadcast( { trump => $game->{trump} } );
		$game->change_state($self->{next});
    }
}

1;
