use strict;
use warnings;

use Test::More;
use Gamed;
use Gamed::Test;
use Gamed::Object;
use Data::Dumper;

my ( $game, $n, $e ) = game(
    [qw/n e/],
    {
        bidder => 1,
        bid    => 135,
        nest   => bag(qw/1R 14R 13R 12R 11R/),
        seat   => [ {}, { cards => bag(qw/5G 6G 7G 8G 9G 5R 6R 7R 8R 9R/) } ],
        state_table => { start => Gamed::Game::Rook::Declaring->new('end'), } } );
like( ref( $game->{state} ), qr/Declaring/, 'Ready to start test' );

$e->got_one( { nest => bag(qw/1R 14R 13R 12R 11R/) }, 'Nest sent to bid winner' );
is( $game->{seat}[1]{cards}, bag(qw/1R 14R 13R 12R 11R 5G 6G 7G 8G 9G 5R 6R 7R 8R 9R/), 'Nest added to player hand' );
$n->game( { trump => 'R' }, { reason => 'Not your turn' },            'Only bid winner declares' );
$e->game( { trump => 'S' }, { reason => "'S' is not a valid trump" }, 'Bad trump choice' );
$e->game( { trump => 'R' }, { reason => "Invalid nest" },             'Missing nest choice' );
$e->game( { trump => 'R', nest => [qw/5G 6G 7G 8G/] },       { reason => "Invalid nest" }, 'Not enough in nest' );
$e->game( { trump => 'R', nest => [qw/5G 6G 7G 8G 9G 4G/] }, { reason => "Invalid nest" }, 'Too many in nest' );
$e->game( { trump => 'R', nest => [qw/5G 6G 7G 9G 9G/] },    { reason => "Invalid nest" }, 'Duplicate card specified' );
$e->game( { trump => 'R', nest => [qw/5G 6G 7G 8G 9Y/] },    { reason => "Invalid nest" }, 'Card not held specified' );
$e->game( { trump => 'R', nest => [qw/5G 6G 7G 8G 9G/] } );
broadcast_one( $game, { trump => 'R' }, 'Chosen trump broadcast' );
is( $game->{trump},          'R',                                        'Trump is set in game' );
is( $game->{nest},           bag(qw/5G 6G 7G 8G 9G/),                    'Nest saved in game' );
is( $game->{seat}[1]{cards}, bag(qw/5R 6R 7R 8R 9R 11R 12R 13R 14R 1R/), 'Player hand set in game' );

done_testing;
