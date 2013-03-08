use Test::More;
use Gamed::Test;
use Data::Dumper;

my $sock = SocketMock->new;
Gamed::on_connect( "test", $sock );
$sock->got_one(
    {
        cmd  => 'gamed',
        games => sub {
            grep { /HiLo/ } @$_[0];
          }
    }
);
Gamed::on_message( "test", json { cmd => "create", game => "HiLo", name => "test" } );
$sock->got_one( { cmd => 'join', game => 'HiLo', name => 'test' } );
ok(1);
done_testing;
