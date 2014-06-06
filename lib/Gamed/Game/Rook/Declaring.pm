package Gamed::Game::Rook::Declaring;

use Gamed::Object;
use Gamed::Handler;
use parent 'Gamed::State';

sub new {
	my ($pkg, %opts) = @_;
	die "$pkg => missing 'next'\n" unless $opts{next};
	bless { name => 'Declaring', next => $opts{next} }, $pkg;
}

sub on_enter_state {
    my $self = shift;
	my $game = $self->{game};
    $game->{players}{ $game->{bidder} }{client}->send( 'nest', { nest => $game->{nest} } );
    $game->{players}{ $game->{bidder} }{cards}->add( $game->{nest} );
    delete $game->{nest};
}

on 'declare' => sub {
    my ( $self, $player, $msg, $player_data ) = @_;
	my $game = $self->{game};
    if ( $player->{in_game_id} ne $game->{bidder} ) {
        $player->err('Not your turn');
        return;
    }

    my $cards = bag( $player_data->{cards} );
    my $nest  = bag( $msg->{nest} );
    if ( $msg->{trump} !~ /^[RGBY]$/ ) {
        $player->err( "'" . $msg->{trump} . "' is not a valid trump" );
    }
    elsif (!defined $msg->{nest}
        || @{ $msg->{nest} } != 5
        || !$nest->subset($cards) )
    {
        $player->err('Invalid nest');
    }
    else {
        $game->{trump} = $msg->{trump};
        $game->{nest}  = bag( $msg->{nest} );
        my $hand = $cards - $nest;
        $player_data->{cards} = $hand;
        $game->broadcast( trump => { trump => $game->{trump} } );
        $game->change_state( $self->{next} );
    }
};

1;
