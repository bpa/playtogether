use Test::More;
use Gamed::Test;
use Data::Dumper;

my $sock = SocketMock->new;
my $id = Gamed::on_connect( "test", $sock );
$sock->got_one(
    {   cmd   => 'gamed',
        games => sub {
            grep {/HiLo/} @$_[0];
          }
    } );
Gamed::on_message( $id, json { cmd => "create", game => "HiLo", name => "test" } );
$sock->got_one( { cmd => 'join', game => 'HiLo', name => 'test' } );
$Gamed::game_instances{'test'}{num} = 175;
Gamed::on_message( $id, json { cmd => "game", guess => 150 } );
$sock->got_one( { cmd => 'game', guesses => 1, answer => 'Too low' } );
Gamed::on_message( $id, json { cmd => "game", guess => 180 } );
$sock->got_one( { cmd => 'game', guesses => 2, answer => 'Too high' } );
Gamed::on_message( $id, json { cmd => "game", guess => 175 } );
$sock->got_one( { cmd => 'game', guesses => 3, answer => 'Correct!' } );
my $new_num = $Gamed::game_instances{'test'}{num};
ok(0 < $new_num && $new_num <= 100, 'new random number');
done_testing;
