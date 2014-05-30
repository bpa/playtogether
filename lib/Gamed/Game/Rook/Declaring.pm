package Gamed::Game::Rook::Declaring;

use Gamed::Object;
parent 'Gamed::State';

sub on_enter_state {
    my $self = shift;
	my $game = $self->{game};
    $game->{players}{ $game->{bidder} }{client}->send( 'nest', { nest => $game->{nest} } );
    $game->{players}{ $game->{bidder} }{cards}->add( $game->{nest} );
    delete $game->{nest};
}

on 'declare' => sub {
    my ( $self, $player, $msg ) = @_;
	my $game = $self->{game};
    if ( $player->{in_game_id} ne $game->{bidder} ) {
        $player->{client}->err('Not your turn');
        return;
    }

    my $cards = bag( $player->{cards} );
    my $nest  = bag( $msg->{nest} );
    if ( $msg->{trump} !~ /^[RGBY]$/ ) {
        $player->{client}->err( "'" . $msg->{trump} . "' is not a valid trump" );
    }
    elsif (!defined $msg->{nest}
        || @{ $msg->{nest} } != 5
        || !$nest->subset($cards) )
    {
        $player->{client}->err('Invalid nest');
    }
    else {
        $game->{trump} = $msg->{trump};
        $game->{nest}  = bag( $msg->{nest} );
        my $hand = $cards - $nest;
        $player->{cards} = $hand;
        $game->broadcast( trump => { trump => $game->{trump} } );
        $game->change_state( $self->{next} );
    }
}

1;
