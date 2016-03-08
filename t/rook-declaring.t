use strict;
use warnings;

use Test::More;
use Test::Deep;
use Gamed;
use Gamed::Test;
use Gamed::Object;
use Data::Dumper;

my ( $game, $n, $e ) = game(
    [qw/n e/],
    {
        game  => 'Declaring',
        seats => [ 0, 1 ],
        bid   => 135,
    },
);
$game->{nest}                       = bag(qw/1R 14R 13R 12R 11R/);
$game->{players}{1}{private}{cards} = bag(qw/5G 6G 7G 8G 9G 5R 6R 7R 8R 9R/);
$game->{state}{bidder}              = 1;
$game->change_state('declaring');
$n->game( { cmd => 'whatever' } );
broadcast( $game, { cmd => 'bidding', bidder => 1, min => 100 } );
broadcast( $game, { cmd => 'bid', bid => 100, bidder => 1 } );
is( $game->{state}{name}, 'Declaring', 'Ready to start test' );

broadcast( $game, { cmd => 'declaring', player => 1 } );
$e->got_one( { nest => code(sub { bag(@{$_[0]}) eq bag(qw/1R 14R 13R 12R 11R/) } ), cmd => ignore() }, 'Nest sent to bid winner' );
is(
    $game->{players}{1}{private}{cards},
    bag(qw/1R 14R 13R 12R 11R 5G 6G 7G 8G 9G 5R 6R 7R 8R 9R/),
    'Nest added to player hand'
);
$n->game( { cmd => 'declare', trump => 'R' }, { cmd => 'error', reason => 'Not your turn' },            'Only bid winner declares' );
$e->game( { cmd => 'declare', trump => 'S' }, { cmd => 'error', reason => "'S' is not a valid trump" }, 'Bad trump choice' );
$e->game( { cmd => 'declare', trump => 'R' }, { cmd => 'error', reason => "Invalid nest" },             'Missing nest choice' );
$e->game(
    { cmd => 'declare', trump => 'R', nest => [qw/5G 6G 7G 8G/] },
    { cmd => 'error', reason => "Invalid nest" },
    'Not enough in nest'
);
$e->game(
    { cmd => 'declare', trump => 'R', nest => [qw/5G 6G 7G 8G 9G 4G/] },
    { cmd => 'error', reason => "Invalid nest" },
    'Too many in nest'
);
$e->game(
    { cmd => 'declare', trump => 'R', nest => [qw/5G 6G 7G 9G 9G/] },
    { cmd => 'error', reason => "Invalid nest" },
    'Duplicate card specified'
);
$e->game(
    { cmd => 'declare', trump => 'R', nest => [qw/5G 6G 7G 8G 9Y/] },
    { cmd => 'error', reason => "Invalid nest" },
    'Card not held specified'
);
$e->game( { cmd => 'declare', trump => 'R', nest => [qw/5G 6G 7G 8G 9G/] } );
broadcast_one( $game, { cmd => 'trump', trump => 'R' }, 'Chosen trump broadcast' );
is( $game->{public}{trump},              'R',                                        'Trump is set in game' );
is( $game->{nest},                       bag(qw/5G 6G 7G 8G 9G/),                    'Nest saved in game' );
is( $game->{players}{1}{private}{cards}, bag(qw/5R 6R 7R 8R 9R 11R 12R 13R 14R 1R/), 'Player hand set in game' );

done_testing;

package Declaring;

use parent 'Gamed::Test::Game::Test';

use Gamed::States {
    start   => Gamed::State::WaitingForPlayers->new( next => 'bidding' ),
    bidding => Gamed::State::Bidding->new(
        next  => 'declaring',
        min   => 100,
        max   => 200,
        valid => sub { $_[0] % 5 == 0 }
    ),
    declaring => Gamed::Game::Rook::Declaring->new(
        name => 'Declaring',
        next => 'end'
    ),
    end => Gamed::State::GameOver->new
};

1;
