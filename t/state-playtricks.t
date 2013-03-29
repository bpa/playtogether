use strict;
use warnings;

use Test::More;
use Gamed;
use Gamed::Test;
use Gamed::Object;
use Data::Dumper;

my ( $game, $n, $e, $s ) = game(
    'Test', 'test',
    [qw/n e s/],
    {
        bidder => 2,
        bid    => 135,
        trump  => 'R',
        seats  => [qw/n e s/],
        seat   => [ { cards => bag(qw/1 3 5 6/) }, { cards => bag(qw/2 7 10 11/) }, { cards => bag(qw/4 8 9 12/) }, ],
        state_table => { start => Gamed::State::PlayTricks->new( 'end', Gamed::Test::PlayLogic->new ), } } );

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
broadcast_one( $game, { trick => [ 4, 1, 2 ], winner => 1 }, 'Trick winner declared' );

is_deeply( $play->{trick}, [], 'Trick reset after all play' );

done_testing;
