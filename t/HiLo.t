use Test::More;
use Gamed::Test;
use Data::Dumper;

my $sock = SocketMock->new;
Gamed::on_connect( "test", $sock );
$sock->got_one(
    {
        cmd   => 'gamed',
        games => sub {
            grep { /HiLo/ } @$_[0];
          }
    }
);
Gamed::on_message( "test",
    json { cmd => "create", game => "HiLo", name => "test" } );
$sock->got_one( { cmd => 'join', game => 'HiLo', name => 'test' } );
$Gamed::game_instances{'test'}{num} = 75;
Gamed::on_message( "test", json { cmd => "game", guess => 50 } );
$sock->got_one( { cmd => 'game', guesses => 1, answer => 'Too low' } );
ok(1);
done_testing;
