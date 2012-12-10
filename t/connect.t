use Test;
use Test::Mock;
use Gamed::Engine;
use Gamed::Network::INET;

my $network = Gamed::Network::INET.new(9999);
#note $network.perl
my $engine = Gamed::Engine.new(
	network => $network
);

my $sock = IO::Socket::INET.new(
	host => '127.0.0.1',
	port => 9999);

$network.poll;
$sock.send('{"user":"test"}');
$network.poll;
my $res = $sock.recv;
is($res, '{"version":'~$Gamed::Engine::version~'"games":[]}');

done;
