use strict;
use warnings;

use Test::More;
use Gamed::Test;

my $one = Gamed::Test::Player->new('test');
my $two = Gamed::Test::Player->new('test2');

$one->game( { cmd => 'create', game => "HiLo", name => "test" }, { cmd => 'create' } );
$two->got_one( { cmd => 'create' } );
$two->game( { cmd => 'create', game => "HiLo", name => "test" },
    { cmd => 'error', reason => "A game named 'test' already exists." } );
$one->broadcast( { cmd => 'join', name => 'test' }, { cmd => 'join' } );
$two->game( { cmd => 'join', name => 'test' },  { cmd => 'error', reason => "Game full" } );
$two->game( { cmd => 'join', name => 'test2' }, { cmd => 'error', reason => "No game named 'test2' exists" } );
$two->game(
    { cmd => 'create', game   => "none", name => "test2" },
    { cmd => 'error',  reason => "No game type 'none' exists" }
);
$one->{game}{number} = 175;
$one->game( { cmd => "guess", guess => 150 }, { cmd => 'guess', guesses => 1, answer => 'Too low' } );
$one->game( { cmd => "guess", guess => 180 }, { cmd => 'guess', guesses => 2, answer => 'Too high' } );
$one->game( { cmd => "guess", guess => 175 }, { cmd => 'guess', guesses => 3, answer => 'Correct!' } );

my $new_num = $one->{game}{number};
ok( 0 < $new_num && $new_num <= 100, 'new random number' );

done_testing;
