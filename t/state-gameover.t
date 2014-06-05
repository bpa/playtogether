use strict;
use warnings;

use Test::More;
use Gamed::Test;
use Data::Dumper;

my ( $game, $p1 ) = game( [1], { game => 'DeadEnd' }, 'start' );

#There is no response to this right now, invalid commands are ignored
$p1->game( { cmd => 'ready' } );
#TODO: Add test for registering timer to destroy game

done_testing;

package DeadEnd;

use parent 'Gamed::Test::Game::Test';

use Gamed::States {
	start => Gamed::State::GameOver->new()
};

1;
