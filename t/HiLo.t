use strict;
use warnings;

use Test::More;
use Gamed::Test;
use Data::Dumper;

my $sock_one = SocketMock->new;
my $sock_two = SocketMock->new;
my $one = Gamed::on_connect( "test", $sock_one );
is(scalar(keys %Gamed::connection), 1);
my $two = Gamed::on_connect( "test", $sock_two );
is(scalar(keys %Gamed::connection), 2);
$sock_one->got_one(
    {   cmd   => 'gamed',
        games => sub {
            grep {/HiLo/} @_;
          }
    } );
$sock_two->got_one;
Gamed::on_message( $one, json { cmd => "create", game => "HiLo", name => "test" } );
Gamed::on_message( $two, json { cmd => "create", game => "HiLo", name => "test" } );
$sock_one->got_one( { cmd => 'join', game => 'HiLo', name => 'test' } );
$sock_two->got_one( { cmd => 'error', reason => "A game named 'test' already exists" } );
Gamed::on_message( $two, json { cmd => "join", game => "HiLo", name => "test" } );
$sock_two->got_one( { cmd => 'error', reason => "Game full" } );
Gamed::on_message( $two, json { cmd => "join", name => "test2" } );
$sock_two->got_one( { cmd => 'error', reason => "No game named 'test2' exists" } );
Gamed::on_message( $two, json { cmd => "create", game => "Test", name => "test2" } );
$sock_two->got_one( { cmd => 'error', reason => "No game type 'Test' exists" } );
Gamed::on_disconnect($two);
is(scalar(keys %Gamed::connection), 1);
$Gamed::game_instances{'test'}{num} = 175;
Gamed::on_message( $one, json { cmd => "game", guess => 150 } );
$sock_one->got_one( { cmd => 'game', guesses => 1, answer => 'Too low' } );
Gamed::on_message( $one, json { cmd => "game", guess => 180 } );
$sock_one->got_one( { cmd => 'game', guesses => 2, answer => 'Too high' } );
Gamed::on_message( $one, json { cmd => "game", guess => 175 } );
$sock_one->got_one( { cmd => 'game', guesses => 3, answer => 'Correct!' } );
my $new_num = $Gamed::game_instances{'test'}{num};
ok(0 < $new_num && $new_num <= 100, 'new random number');
done_testing;
