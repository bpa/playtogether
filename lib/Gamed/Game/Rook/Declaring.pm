package Gamed::Game::Rook::Declaring;

use Moose;
use Gamed::Object;
use namespace::clean;

extends 'Gamed::State';

has '+name' => ( default => 'Declaring' );
has 'next' => ( is => 'bare', required => 1 );

sub on_enter_state {
    my ( $self, $game ) = @_;
    $game->{players}{ $game->{bidder} }{client}->send( 'nest', { nest => $game->{nest} } );
    $game->{players}{ $game->{bidder} }{cards}->add( $game->{nest} );
    delete $game->{nest};
}

sub on_message {
    my ( $self, $game, $player, $msg ) = @_;
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

__PACKAGE__->meta->make_immutable;
