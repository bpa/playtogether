package Gamed::Game::RoboRally::Programming;

use Gamed::Handler;
use Gamed::Object::Bag;
use List::Util qw/shuffle/;
use parent 'Gamed::State';

sub new {
    my ( $pkg, %opts ) = @_;
    bless { name => 'Programming', next => $opts{next} }, $pkg;
}

sub on_enter_state {
    my ( $self, $game ) = @_;

    $game->{movement_cards}->reset->shuffle;
    for my $p ( values %{ $game->{players} } ) {
        my $cards = 9 - $p->{public}{damage};
        $p->{private}{cards} = Gamed::Object::Bag->new( $game->{movement_cards}->deal($cards) );
        $p->{client}->send( programming => { cards => $p->{private}{cards} } );
    }
}

on 'quit' => sub {
    my ( $self, $player, $msg, $player_data ) = @_;
    my $game = $self->{game};
    delete $player_data->{client};
    $player_data->{public}{ready} = 1;
    my @remaining = grep { exists $_->{client} } values %{ $game->{players} };
    if ( @remaining == 1 ) {
        $game->broadcast( victory => { player => $remaining[0]->{public}{id} } );
        $game->change_state('GAME_OVER');
    }
    else {
        $game->change_state( $self->{next} )
          unless grep { !$_->{public}{ready} } values %{ $game->{players} };
    }
};

1;
