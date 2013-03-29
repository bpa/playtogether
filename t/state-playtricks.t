use strict;
use warnings;

use Test::More;
use Gamed;
use Gamed::Test;
use Gamed::Object;
use Data::Dumper;

my ( $game, $n, $e, $s, $w ) = game(
    'Test', 'test',
    [qw/n e s w/],
    {
        bidder => 2,
        bid => 135,
        trump => 'R',
        seats       => [qw/n e s w/],
        nest => bag(qw/5G 6G 7G 8G 9G/),
        seat => [
            { cards => bag(qw/10G 12R 11R 14Y 9Y 8Y 1B 11B 9B 7B/) },
            { cards => bag(qw/11G 14R 8R 6R 13Y 7Y 6Y 14B 12B 5B/) },
            { cards => bag(qw/12G 1G 1R 13R 9R 7R 5R 1Y 10Y 13B/) },
            { cards => bag(qw/13G 14G 10R 12Y 11Y 5Y 13B 10B 8B 6B/) },
        ],
        state_table => {
            start => Gamed::State::PlayTricks->new('end', Gamed::Game::Rook::PlayLogic->new),
        } } );

my $play = $game->{state};
like(ref($play), qr/PlayTricks/);
$n->game( { play => '10G' }, { reason => 'Not your turn' } );
$s->game( { play => '1B' }, { reason => 'Invalid card' } );

broadcasted( $game, $s, { play => '1Y' }, { player => 's', play => '1Y' } );
is_deeply( $play->{trick}, ['1Y'], 'Card added to trick' );
ok( !$game->{seat}[2]{cards}->contains('1Y'), 'Card removed from hand' );

done_testing;
