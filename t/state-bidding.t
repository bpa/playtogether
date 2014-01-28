use strict;
use warnings;

use Test::More;
use Gamed::Test;
use Data::Dumper;

my ( $game, $n, $e, $s ) = game(
    [qw/n e s/],
    {
        state_table => {
            start => Gamed::State::Bidding->new(
                next  => 'end',
                min   => 100,
                max   => 200,
                valid => sub { $_[0] % 5 == 0 },
            ),
            end => Gamed::State->new( name => 'end' ) }
    },
    'start'
);

$e->game( { bid => 100 }, { reason => 'Not your turn' },         "Bid out of turn" );
$n->game( { bid => 50 },  { reason => 'Bidding starts at 100' }, "Bid too low" );
$n->game( { bid => 205 }, { reason => 'Max bid is 200' },        "Bid too high" );
$n->game( { bid => 103 }, { reason => 'Invalid bid' },
    "Must bid in multiples of 5" );

$n->game( { bid => 100 } );
broadcast_one( $game, { bid => 100, player => 0 }, 'bid was broadcast' );
$e->game( { bid => 105 } );
broadcast_one( $game, { bid => 105, player => 1 }, 'bid was broadcast' );
$s->game( { bid => 105 }, { reason => 'You must bid up or pass' } );

$s->game( { bid => 'pass' } );
broadcast_one( $game, { bid => 'pass', player => 2 }, 'pass was broadcast' );
$n->game( { bid => 120 } );
broadcast_one( $game, { bid => 120, player => 0 }, 'bid was broadcast' );
$e->game( { bid => 125 } );
broadcast_one( $game, { bid => 125, player => 1 }, 'bid was broadcast' );
$s->game( { bid => 130 }, { reason => 'Not your turn' }, "Can't bid after pass" );
$n->game( { bid => 'pass' } );
broadcast( $game, { bid => 'pass', player => 0 }, 'pass was broadcast' );
broadcast_one( $game, { bidder => 1, bid => 125 }, 'Bid winner declared' );
is( $game->{bid},          125,            "Game's bid got set" );
is( $game->{bidder},       1,              "Game's bidder got set" );
is( ref( $game->{state} ), 'Gamed::State', "State changed" );

( $game, $n, $s ) = game(
    [qw/n s/],
    {   name        => 'test2',
        seat        => [ {}, {} ],
        state_table => {
            start => Gamed::State::Bidding->new(
                {   next  => 'end',
                    min   => 25,
                    max   => 50,
                    valid => sub {1},
                }
            ),
            end => Gamed::State->new( name => 'end' ) }
    },
    'start'
);

is( $game->{state}->name, 'Bidding', "initial state" );
$n->game( { bid => 30 } );
broadcast_one($game);
$s->game( { bid => 'pass' } );
broadcast($game);
broadcast_one($game);
is( ref( $game->{state} ), 'Gamed::State', "State changed" );
$game->change_state('start');
$game->change_state_if_requested;
$n->game(
    { bid    => 35 },
    { reason => 'Not your turn' },
    'Bidding switches to next player on return'
);
$s->game( { bid => 25 } );
broadcast_one( $game, { bid => 25, player => 1 }, 'Old state info is cleared' );

done_testing;
