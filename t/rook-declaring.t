use strict;
use warnings;

use Test::More;
use Gamed;
use Gamed::Test;
use Data::Dumper;
use Set::Object;

my ( $game, $n, $e ) = game(
    'Test', 'test',
    [qw/n e/],
    {
        seats       => [qw/n e/],
        bidder      => 1,
        bid         => 135,
        nest        => cards(qw/1R 14R 13R 12R 11R/),
        state_table => {
            start => Gamed::Game::Rook::Declaring->new('end'),
        } } );
like(ref($game->{state}), qr/Declaring/, 'Ready to start test');
$game->{seat}[1]{cards} = cards(qw/5G 6G 7G 8G 9G 5R 6R 7R 8R 9R/);

$e->got_one( { nest => cards(qw/1R 14R 13R 12R 11R/) }, 'Nest sent to bid winner' );
$n->game( { trump => 'R' }, { reason => 'Not your turn' }, 'Only bid winner declares' );
$e->game( { trump => 'S' }, { reason => "'S' is not a valid trump" }, 'Bad trump choice' );
$e->game( { trump => 'R' }, { reason => "Invalid nest" }, 'Missing nest choice' );
$e->game( { trump => 'R', nest => [qw/5G 6G 7G 8G/] }, { reason => "Invalid nest" }, 'Not enough in nest' );
$e->game( { trump => 'R', nest => [qw/5G 6G 7G 8G 9G 4G/] }, { reason => "Invalid nest" }, 'Too many in nest' );
$e->game( { trump => 'R', nest => [qw/5G 6G 7G 9G 9G/] }, { reason => "Invalid nest" }, 'Duplicate card specified' );
$e->game( { trump => 'R', nest => [qw/5G 6G 7G 8G 9Y/] }, { reason => "Invalid nest" }, 'Card not held specified' );
$e->game( { trump => 'R', nest => [qw/5G 6G 7G 8G 9G/] } );
broadcast( $game, { trump => 'R' }, 'Chosen trump broadcast' );
broadcast_one( $game, { state => 'end' } );
is($game->{trump}, 'R', 'Trump is set in game');
hand_is($game->{nest}, cards(qw/5G 6G 7G 8G 9G/), 'Nest saved in game');
hand_is($game->{seat}[1]{cards}, cards(qw/5R 6R 7R 8R 9R 11R 12R 13R 14R 1R/), 'Player hand set in game');

done_testing;

sub hand_is {
    #my $nest = set(map($_->TO_JSON, @{$game->{nest}}));
    #if ($nest == set(qw/5G 6G 7G 8G 9G/) {
    #    ok('Nest saved in game');
    #}
}

sub cards {
    my @hand;
    for (@_) {
        push @hand, Gamed::Object::Card::Rook->new(@_);
    }
    return \@hand;
}
