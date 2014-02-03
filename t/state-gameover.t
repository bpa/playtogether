use strict;
use warnings;

use Test::More;
use Gamed::Test;
use Data::Dumper;

my ( $game, $p1 )
  = game( [1], { state_table => { start => Gamed::State::GameOver->new(), } },
    'start' );

$p1->game( { cmd => 'ready' }, { cmd => 'error', reason => 'Invalid command' } );
#TODO: Add test for registering timer to destroy game

done_testing;
