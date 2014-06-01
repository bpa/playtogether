use strict;
use warnings;

use Test::More;
use Gamed::Test;

my $one = Gamed::Test::Player->new('test');
my $two = Gamed::Test::Player->new('test2');

$one->handle( { cmd => 'create', game => "HiLo", name => "test" } );
$two->handle( { cmd => 'create', game => "HiLo", name => "test" } );
$two->got_one( { cmd => 'error', reason => "A game named 'test' already exists." } );
$one->handle( { cmd => 'join', name => 'test' } );
$one->got_one( { cmd => 'join', player => 0 } );
$two->handle( { cmd => 'join', name => 'test' } );
$two->got_one( { cmd => 'error', reason => "Game full" } );
$two->handle( { cmd => 'join', name => 'test2' } );
$two->got_one( { cmd => 'error', reason => "No game named 'test2' exists" } );
$two->handle( { cmd => 'create', game => "none", name => "test2" } );
$two->got_one( { cmd => 'error', reason => "No game type 'none' exists" } );
$one->{game}{number} = 175;
$one->handle( { cmd => "guess", guess => 150 } );
$one->got_one( { cmd => 'guess', guesses => 1, answer => 'Too low' } );
$one->handle( { cmd => "guess", guess => 180 } );
$one->got_one( { cmd => 'guess', guesses => 2, answer => 'Too high' } );
$one->handle( { cmd => "guess", guess => 175 } );
$one->got_one( { cmd => 'guess', guesses => 3, answer => 'Correct!' } );
my $new_num = $one->{game}{number};
ok( 0 < $new_num && $new_num <= 100, 'new random number' );

done_testing;
