use strict;
use warnings;

use Test::More;
use Gamed::Test;
use Data::Dumper;

my ( $game, $n, $e, $s ) = game(
    'Test', 'test',
    [qw/n e s/],
    {
        seats       => [qw/n e s/],
        state_table => {
            start => Gamed::State::Bidding->new(
                {
                    next  => 'end',
                    min   => 100,
                    max   => 200,
                    valid => sub { $_[0] % 5 == 0 },
                } ) } } );

$e->game( { bid => 100 }, { reason => 'Not your turn' },         "Bid out of turn" );
$n->game( { bid => 50 },  { reason => 'Bidding starts at 100' }, "Bid too low" );
$n->game( { bid => 205 }, { reason => 'Max bid is 200' },        "Bid too high" );
$n->game( { bid => 103 }, { reason => 'Invalid bid' },           "Must bid in multiples of 5" );

$n->game( { bid => 100 } );
broadcast_one( $game, { bid => 100, player => 'n' }, 'bid was broadcast' );
$e->game( { bid => 105 } );
broadcast_one( $game, { bid => 105, player => 'e' }, 'bid was broadcast' );
$s->game( { bid => 105 }, { reason => 'You must bid up or pass' } );

$s->game( { bid => 'pass' } );
broadcast_one( $game, { bid => 'pass', player=>'s' }, 'pass was broadcast' );
$n->game( { bid => 120 } );
broadcast_one( $game, { bid => 120, player=>'n' }, 'bid was broadcast' );
$e->game( { bid => 125 } );
broadcast_one( $game, { bid => 125, player=>'e' }, 'bid was broadcast' );
$s->game( { bid => 130 } , { reason => 'Not your turn' }, "Can't bid after pass" );
$n->game( { bid => 'pass' } );
broadcast( $game, { bid => 'pass', player=>'n' }, 'pass was broadcast' );
broadcast( $game, { bidder=>'e', bid => 125 }, 'Bid winner declared' );
broadcast_one( $game, { state => 'end' }, 'Changing state to picking' );
is( $game->{bid}, 125, "Game's bid got set");
is( $game->{bidder}, 1, "Game's bidder got set");
is( ref( $game->{state} ), 'Gamed::State', "State changed" );

( $game, $n, $s ) = game(
    'Test', 'test2',
    [qw/n s/],
    {
        seats       => [qw/n s/],
        state_table => {
            start => Gamed::State::Bidding->new(
                {
                    next  => 'end',
                    min   => 25,
                } ) } } );

like( ref( $game->{state} ), qr/Bidding/, "initial state" );
$n->game( { bid => 30 } );
broadcast_one( $game );
$s->game( { bid => 'pass' } );
broadcast( $game );
broadcast( $game );
broadcast_one( $game );
is( ref( $game->{state} ), 'Gamed::State', "State changed" );
$game->change_state('start');
broadcast( $game );
$n->game( { bid => 35 }, { reason => 'Not your turn' }, 'Bidding switches to next player on return');
$s->game( { bid => 25 } );
broadcast_one( $game, { bid => 25, player => 's' }, 'Old state info is cleared' );

done_testing;
