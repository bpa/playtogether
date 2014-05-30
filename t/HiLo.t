use strict;
use warnings;

use Test::More;
use Gamed::Test;
use Data::Dumper;

my $one = Gamed::Test::Player->new('test');
my $two = Gamed::Test::Player->new('test2');

$one->handle( { cmd => 'create', game => "HiLo", name => "test" } );
eval { $two->handle( { cmd => 'create', game => "HiLo", name => "test" } ) };
is( $@, "A game named 'test' already exists.\n" );
$one->handle( { cmd => 'join', name => 'test' } );
$one->got_one( { cmd => 'join', player => 0 } );
$two->handle( { cmd => 'join', name => 'test' } );
$two->got_one( { cmd => 'error', reason => "Game full" } );
$two->handle( { cmd => 'join', name => 'test2' } );
$two->got_one( { cmd => 'error', reason => "No game named 'test2' exists" } );
eval { $two->handle( { cmd => 'create', game => "none", name => "test2" } ) };
is( $@, "No game type 'none' exists\n" );
$Gamed::game_instances{'test'}{num} = 175;
$one->handle( { cmd => "game", guess => 150 } );
$one->got_one( { cmd => 'game', guesses => 1, answer => 'Too low' } );
$one->handle( { cmd => "game", guess => 180 } );
$one->got_one( { cmd => 'game', guesses => 2, answer => 'Too high' } );
$one->handle( { cmd => "game", guess => 175 } );
$one->got_one( { cmd => 'game', guesses => 3, answer => 'Correct!' } );
my $new_num = $Gamed::game_instances{'test'}{num};
ok( 0 < $new_num && $new_num <= 100, 'new random number' );

done_testing;
