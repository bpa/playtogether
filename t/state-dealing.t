use strict;
use warnings;

use Test::More;
use Gamed::Test;
use Data::Dumper;
use Test::Builder;
my $tb = Test::Builder->new;

my ( $game, $n, $e, $s, $w ) = game( [qw/n e s w/], { game => 'Dealing' }, 'dealing' );

broadcast_one( $game, { cmd => 'dealing', dealer => 0 }, 'Dealer announced' );
$e->game( { cmd => 'deal' }, { reason => 'Not your turn' }, 'Deal out of turn' );
$n->game( { cmd => 'deal' } );
my $rook = qr/(\d+[RGBY])|0/;
check_deal( $rook, 10 );
is( scalar( $game->{nest}->values ), 5, "5 cards in the nest" );

change_state( $game, 'dealing' );
$e->game( { cmd => 'deal' } );
check_deal( $rook, 10 );
is( scalar( $game->{nest}->values ), 5, "5 cards in the nest" );

$game->{states}{dealing}{deck}   = Gamed::Object::Deck::FrenchSuited->new('normal');
$game->{states}{dealing}{deal}   = { seat => 13 };
$game->{states}{dealing}{dealer} = 0;

change_state( $game, 'dealing' );
my $french = qr/([\dJQKA]+[SHCD])/;
$n->game( { cmd => 'deal' } );
check_deal( $french, 13 );

$game->{states}{dealing}{deal} = { seat => 13, dummy => 13 };
pop @{ $game->{seat} };
delete $game->{players}{3};
change_state( $game, 'dealing' );
$e->game( { cmd => 'deal' } );
check_deal( $french, 13 );
is( scalar( $game->{dummy}->values ), 13, "13 cards to dummy" );

sub check_deal {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $re, $cards ) = @_;
    broadcast_one(
        $game,
        {
            hand => sub { grep( /$re/, @{ $_[0] } ) == $cards }
        },
        'Hand Dealt'
    );
    for my $s ( values %{ $game->{players} } ) {
        is( scalar( $s->{cards}->values ), $cards, "Game kept record of cards dealt to player" );
    }
    is( $game->{leader}, $game->{states}{dealing}{dealer}, 'leader set' );
    is( ref( $game->{state} ), 'Gamed::State::GameOver', "Finished dealing" );
}

sub change_state {
    my ( $game, $state ) = @_;
    $game->change_state($state);
    $game->handle( $n, { cmd => 'change_state' } );
    broadcast_one($game);
}

done_testing;

package Dealing;

use parent 'Gamed::Test::Game::Test';

use Gamed::States {
    start   => Gamed::State::WaitingForPlayers->new( next => 'dealing' ),
    dealing => Gamed::State::Dealing->new(
        next => 'end',
        deck => Gamed::Object::Deck::Rook->new('partnership'),
        deal => { seat => 10, nest => 5 },
    ),
    end => Gamed::State::GameOver->new
};

1;
