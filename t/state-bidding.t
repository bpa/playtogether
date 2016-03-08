use strict;
use warnings;

use Test::More;
use Test::Deep;
use Gamed::Test;
use Data::Dumper;

my ( $game, $n, $e, $s ) = game( [qw/n e s/], { game => 'BidBy5' }, 'bidding' );
broadcast_one( $game, { cmd => 'bidding', bidder => 1, min => ignore() } );

#Bidding starts with the 2nd player (e)
$s->game( { cmd => 'bid', bid => 100 }, { cmd => 'error', reason => 'Not your turn' },         "Bid out of turn" );
$e->game( { cmd => 'bid', bid => 50 },  { cmd => 'error', reason => 'Bidding starts at 100' }, "Bid too low" );
$e->game( { cmd => 'bid', cmd => 'bid', bid => 205 }, { cmd => 'error', reason => 'Max bid is 200' }, "Bid too high" );
$e->game( { cmd => 'bid', bid => 103 }, { cmd => 'error', reason => 'Invalid bid' }, "Must bid in multiples of 5" );

$e->broadcast( { cmd => 'bid', bid => 100 }, { cmd => 'bid', bid => 100, player => 1, bidder => 2 }, 'bid was broadcast' );
$s->broadcast( { cmd => 'bid', bid => 105 }, { cmd => 'bid', bid => 105, player => 2, bidder => 0 }, 'bid was broadcast' );
$n->game( { cmd => 'bid', bid => 105 }, { cmd => 'error', reason => 'You must bid up or pass' } );

$n->broadcast( { cmd => 'bid', bid => 'pass' }, { cmd => 'bid', bid => 'pass', player => 0, bidder => 1 }, 'pass was broadcast' );
$e->broadcast( { cmd => 'bid', bid => 120 }, { cmd => 'bid', bid => 120, player => 1, bidder => 2 }, 'bid was broadcast' );
$s->broadcast( { cmd => 'bid', bid => 125 }, { cmd => 'bid', bid => 125, player => 2, bidder => 1 }, 'bid was broadcast' );
$n->game( { cmd => 'bid', bid => 130 }, { cmd => 'error', reason => 'Not your turn' }, "Can't bid after pass" );
$e->game( { cmd => 'bid', bid => 'pass' } );
broadcast( $game, { cmd => 'bid', bid => 'pass', player => 1, bidder => 2 }, 'pass was broadcast' );
broadcast_one( $game, { cmd => 'bid', bidder => 2, bid => 125 }, 'Bid winner declared' );
is( $game->{public}{bid},    125,                      "Game's bid got set" );
is( $game->{public}{bidder}, 2,                        "Game's bidder got set" );
is( ref( $game->{state} ),    'Gamed::State::GameOver', "State changed" );

( $game, $n, $s ) = game( [qw/n s/], { game => 'BidBy1', name => 'test2' }, 'bidding' );
broadcast_one( $game, { cmd => 'bidding', bidder => 1, min => 25 } );

is( $game->{state}{name}, 'Bidding', "initial state" );
$s->broadcast( { cmd => 'bid', bid => 30, bidder => 0, player => 1 } );

#broadcast_one($game);
$n->game( { cmd => 'bid', bid => 'pass' } );
broadcast($game, { cmd => 'bid', bid => 'pass', player => 0, bidder => 1 } );
broadcast_one($game, { cmd => 'bid', bidder => 1, bid => 30 } );
is( ref( $game->{state} ), 'Gamed::State::GameOver', "State changed" );
$game->change_state('bidding');
$game->handle( $n, { cmd => 'do it' } );
broadcast_one( $game, { cmd => 'bidding', bidder => 0, min => 25 } );
$s->game( { cmd => 'bid', bid => 35 }, { cmd => 'error', reason => 'Not your turn' }, 'Bidding switches to next player on return' );
$n->game( { cmd => 'bid', bid => 25 } );
broadcast_one( $game, { bid => 25, player => 0, cmd => 'bid', bidder => 1 }, 'Old state info is cleared' );

done_testing;

package BidBy5;

use parent 'Gamed::Test::Game::Test';

use Gamed::States {
    start   => Gamed::State::WaitingForPlayers->new( next => 'bidding' ),
    bidding => Gamed::State::Bidding->new(
        next  => 'end',
        min   => 100,
        max   => 200,
        valid => sub { $_[0] % 5 == 0 },
    ),
    end => Gamed::State::GameOver->new
};

package BidBy1;

use parent 'Gamed::Test::Game::Test';

use Gamed::States {
    start   => Gamed::State::WaitingForPlayers->new( next => 'bidding' ),
    bidding => Gamed::State::Bidding->new(
        next  => 'end',
        min   => 25,
        max   => 50,
        valid => sub {1},
    ),
    end => Gamed::State::GameOver->new
};

1;
