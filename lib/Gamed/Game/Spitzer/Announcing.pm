package Gamed::Game::Spitzer::Announcing;

use Gamed::Object;
use Gamed::Handler;
use parent 'Gamed::State';

sub new {
    my ( $pkg, %opts ) = @_;
    bless { name => 'Announcing' }, $pkg;
}

sub on_enter_state {
    my ( $self, $game ) = @_;
    $game->{players}{ $game->{public}{bidder} }{client}->send( 'nest', { nest => $game->{nest} } );
    $game->{players}{ $game->{public}{bidder} }{private}{cards}->add( $game->{nest} );
    delete $game->{nest};
}

on 'declare' => sub {
    my ( $self, $player, $msg, $player_data ) = @_;
    my $game = $self->{game};
    if ( $player->{in_game_id} ne $game->{public}{bidder} ) {
        $player->err('Not your turn');
        return;
    }

    my $cards = bag( $player_data->{private}{cards} );
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
        $game->{public}{trump} = $msg->{trump};
        $game->{nest}  = bag( $msg->{nest} );
        my $hand = $cards - $nest;
        $player_data->{private}{cards} = $hand;
        $game->broadcast( trump => { trump => $game->{public}{trump} } );
        $game->change_state( $self->{next} );
    }
};

1;
1;
