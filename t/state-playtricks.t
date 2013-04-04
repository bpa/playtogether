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
        leader => 2,
        bidder => 2,
        bid    => 135,
        trump  => 'R',
        seat   => [ { cards => bag(qw/1 5 13 14/) }, 
					{ cards => bag(qw/2 9 11 15/) },
					{ cards => bag(qw/4 8 12 16/) }, ],
        state_table => { start => Gamed::State::PlayTricks->new( Gamed::Test::PlayLogic->new ), } } );

my $play = $game->{state};
like( ref($play), qr/PlayTricks/ );
$n->game( { play => 1 }, { reason => 'Not your turn' } );
$s->game( { play => 8 }, { reason => 'Invalid card' } );

$s->game( { play => 4 } );
broadcast_one( $game, { player => 2, play => 4 }, 'Card played was sent to everyone' );
is_deeply( $play->{trick}, [4], 'Card added to trick' );
ok( !$game->{seat}[2]{cards}->contains(4), 'Card removed from hand' );

broadcasted( $game, $n, { play => 1 }, { player => 0, play => 1 }, 'N plays a 1' );
is_deeply( $play->{trick}, [ 4, 1 ], 'Card added to trick' );
broadcasted( $game, $e, { play => 2 }, { player => 1, play => 2 } );
broadcast_one( $game, { trick => [ 4, 1, 2 ], winner => 2 }, 'Trick winner declared' );

is_deeply( $play->{trick}, [], 'Trick reset after all play' );
is_deeply( $game->{seat}[2]{taken}, [ 4, 1, 2 ], "Captured trick given to player" );

broadcasted( $game, $s, { play => 8 }, { player => 2, play => 8 }, 'Round 2' );
broadcasted( $game, $n, { play => 5 }, { player => 0, play => 5 }, 'Round 2' );
broadcasted( $game, $e, { play => 9 }, { player => 1, play => 9 }, 'Round 2' );
broadcast_one( $game, { trick => [ 8, 5, 9 ], winner => 1 }, 'Trick winner declared' );
is_deeply( $game->{seat}[1]{taken}, [ 8, 5, 9 ], "Captured trick given to player" );

broadcasted( $game, $e, { play => 11 }, { player => 1, play => 11 }, 'Round 3' );
broadcasted( $game, $s, { play => 12 }, { player => 2, play => 12 }, 'Round 3' );
broadcasted( $game, $n, { play => 13 }, { player => 0, play => 13 }, 'Round 3' );
broadcast( $game, { trick => [ 11, 12, 13 ], winner => 0 }, 'Trick winner declared' );
is_deeply( $game->{seat}[0]{taken}, [ 11, 12, 13 ], "Captured trick given to player" );

broadcasted( $game, $n, { play => 14 }, { player => 0, play => 14 }, 'Round 3' );
broadcasted( $game, $e, { play => 15 }, { player => 1, play => 15 }, 'Round 3' );
broadcasted( $game, $s, { play => 16 }, { player => 2, play => 16 }, 'Round 3' );
broadcast( $game, { trick => [ 14, 15, 16 ], winner => 2 }, 'Trick winner declared' );
is_deeply( $game->{seat}[2]{taken}, [ 4, 1, 2, 14, 15, 16 ], "Captured trick doesn't overwrite other captured tricks" );

is( ref( $game->{state} ), 'Gamed::State', 'Changed state' );

done_testing;
