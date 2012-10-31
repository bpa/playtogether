use v6;
use Test;
use Gamed::Engine;
use Gamed::Network::INET;

my $network = Gamed::Network::INET.new(9999);
my $engine = Gamed::Engine.new(
	network => $network
);

my $sock = IO::Socket::INET.new(
	host => '127.0.0.1',
	port => 9999);

$network.poll;
$sock.send('{"user":"test"}');
$network.poll;
my $res = recv($sock);
is($res, '{"version":"'~$Gamed::Engine::version~'","games":[]}');
done;

sub recv (IO::Socket $sock) {
	if $sock.poll(1, .05) {
		return $sock.recv();
	}
	return;
}
