use strict;
use warnings;

use Test::More;
use Test::Deep;
use Gamed;
use Gamed::Test;
use Gamed::Object;
use Data::Dumper;

my ( $game, $n, $e, $s ) = game(
    [qw/n e s/],
    {   game   => 'PlayTricks',
        public => {
            player => 2,
            bidder => 2,
            bid    => 135,
            trump  => 'R',
        },
        seats => [ 0, 1, 2 ],
    },
);
is( $game->{state}{name}, 'PlayTricks' );
$game->{players}{0}{private}{cards} = bag(qw/1 5 13 14/);
$game->{players}{1}{private}{cards} = bag(qw/2 9 11 15/);
$game->{players}{2}{private}{cards} = bag(qw/4 8 12 16/);

$n->game( { cmd => 'play', card => 1 }, { cmd => 'error', reason => 'Not your turn' } );
$s->game( { cmd => 'play', card => 8 }, { cmd => 'error', reason => 'Invalid card', card => 8, cards => ignore() } );

$s->game( { cmd => 'play', card => 4 } );
broadcast_one( $game, { player => 2, card => 4, cmd => 'play', next => 0 }, 'Card played was sent to everyone' );
is_deeply( $game->{public}{trick}, [4], 'Card added to trick' );
ok( !$game->{players}{2}{private}{cards}->contains(4), 'Card removed from hand' );

broadcasted( $game, $n, { cmd => 'play', card => 1 }, { player => 0, card => 1, cmd => 'play', next => 1 }, 'N plays a 1' );
is_deeply( $game->{public}{trick}, [ 4, 1 ], 'Card added to trick' );
$e->broadcast( { cmd => 'play', card => 2 }, { trick => [ 4, 1, 2 ], winner => 2, cmd => 'trick', leader => 2 }, 'Trick winner declared' );

is_deeply( $game->{public}{trick}, [], 'Trick reset after all play' );
is_deeply( $game->{players}{2}{taken}, [ 4, 1, 2 ], "Captured trick given to player" );

broadcasted( $game, $s, { cmd => 'play', card => 8 }, { player => 2, card => 8, cmd => 'play', next => 0 }, 'Round 2' );
broadcasted( $game, $n, { cmd => 'play', card => 5 }, { player => 0, card => 5, cmd => 'play', next => 1 }, 'Round 2' );
$e->broadcast( { cmd => 'play', card => 9 }, { trick => [ 8, 5, 9 ], winner => 1, cmd => 'trick', leader => 2 }, 'Trick winner declared' );
is_deeply( $game->{players}{1}{taken}, [ 8, 5, 9 ], "Captured trick given to player" );

broadcasted( $game, $e, { cmd => 'play', card => 11 }, { player => 1, card => 11, cmd => 'play', next => 2 }, 'Round 3' );
broadcasted( $game, $s, { cmd => 'play', card => 12 }, { player => 2, card => 12, cmd => 'play', next => 0 }, 'Round 3' );
$n->broadcast( { cmd => 'play', card => 13 }, { trick => [ 11, 12, 13 ], winner => 0, cmd => 'trick', leader => 1 }, 'Trick winner declared' );
is_deeply( $game->{players}{0}{taken}, [ 11, 12, 13 ], "Captured trick given to player" );

broadcasted( $game, $n, { cmd => 'play', card => 14 }, { player => 0, card => 14, cmd => 'play', next => 1 }, 'Round 3' );
broadcasted( $game, $e, { cmd => 'play', card => 15 }, { player => 1, card => 15, cmd => 'play', next => 2 }, 'Round 3' );
$s->broadcast( { cmd => 'play', card => 16 }, { trick => [ 14, 15, 16 ], winner => 2, cmd => 'trick', leader => 0 }, 'Trick winner declared' );
is_deeply(
    $game->{players}{2}{taken},
    [ 4, 1, 2, 14, 15, 16 ],
    "Captured trick doesn't overwrite other captured tricks"
);

is( ref( $game->{state} ), 'Gamed::State::GameOver', 'Changed state' );

done_testing;

package PlayTricks;

use parent 'Gamed::Test::Game::Test';

use Gamed::States {
    start => Gamed::State::PlayTricks->new( next => 'end', logic => Gamed::Test::PlayLogic->new ),
    end   => Gamed::State::GameOver->new
};

1;
