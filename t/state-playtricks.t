use strict;
use warnings;

use Test::More;
use Gamed;
use Gamed::Test;
use Gamed::Object;
use Data::Dumper;

my ( $game, $n, $e, $s ) = game(
    [qw/n e s/],
    {
        game    => 'PlayTricks',
        leader  => 2,
        bidder  => 2,
        bid     => 135,
        trump   => 'R',
        players => {
            0 => { cards => bag(qw/1 5 13 14/) },
            1 => { cards => bag(qw/2 9 11 15/) },
            2 => { cards => bag(qw/4 8 12 16/) },
        },
    },
);

is( $game->{state}{name}, 'PlayTricks' );
$n->game( { cmd => 'play', play => 1 }, { reason => 'Not your turn' } );
$s->game( { cmd => 'play', play => 8 }, { reason => 'Invalid card' } );

$s->game( { cmd => 'play', play => 4 } );
broadcast_one( $game, { player => 2, play => 4 }, 'Card played was sent to everyone' );
is_deeply( $game->{state}{trick}, [4], 'Card added to trick' );
ok( !$game->{players}{2}{cards}->contains(4), 'Card removed from hand' );

broadcasted( $game, $n, { cmd => 'play', play => 1 }, { player => 0, play => 1 }, 'N plays a 1' );
is_deeply( $game->{state}{trick}, [ 4, 1 ], 'Card added to trick' );
broadcasted( $game, $e, { cmd => 'play', play => 2 }, { player => 1, play => 2 } );
broadcast_one( $game, { trick => [ 4, 1, 2 ], winner => 2 }, 'Trick winner declared' );

is_deeply( $game->{state}{trick}, [], 'Trick reset after all play' );
is_deeply( $game->{players}{2}{taken}, [ 4, 1, 2 ], "Captured trick given to player" );

broadcasted( $game, $s, { cmd => 'play', play => 8 }, { player => 2, play => 8 }, 'Round 2' );
broadcasted( $game, $n, { cmd => 'play', play => 5 }, { player => 0, play => 5 }, 'Round 2' );
broadcasted( $game, $e, { cmd => 'play', play => 9 }, { player => 1, play => 9 }, 'Round 2' );
broadcast_one( $game, { trick => [ 8, 5, 9 ], winner => 1 }, 'Trick winner declared' );
is_deeply( $game->{players}{1}{taken}, [ 8, 5, 9 ], "Captured trick given to player" );

broadcasted( $game, $e, { cmd => 'play', play => 11 }, { player => 1, play => 11 }, 'Round 3' );
broadcasted( $game, $s, { cmd => 'play', play => 12 }, { player => 2, play => 12 }, 'Round 3' );
broadcasted( $game, $n, { cmd => 'play', play => 13 }, { player => 0, play => 13 }, 'Round 3' );
broadcast( $game, { trick => [ 11, 12, 13 ], winner => 0 }, 'Trick winner declared' );
is_deeply( $game->{players}{0}{taken}, [ 11, 12, 13 ], "Captured trick given to player" );

broadcasted( $game, $n, { cmd => 'play', play => 14 }, { player => 0, play => 14 }, 'Round 3' );
broadcasted( $game, $e, { cmd => 'play', play => 15 }, { player => 1, play => 15 }, 'Round 3' );
broadcasted( $game, $s, { cmd => 'play', play => 16 }, { player => 2, play => 16 }, 'Round 3' );
broadcast( $game, { trick => [ 14, 15, 16 ], winner => 2 }, 'Trick winner declared' );
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
