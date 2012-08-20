use v6;
use Test;
use Test::Mock;
use Gamed::Engine;
use Gamed::Network::libevent;

my $libevent = Gamed::Network::libevent.new(port=>9999);
my $engine = Gamed::Engine.new(
	network => $libevent
);

my $sock = IO::Socket::INET.new(
	host => '127.0.0.1',
	port => '9999');

$libevent.run_once;
$sock.send('{"user":"test"}');
$libevent.run_once;
my $res = $sock.recv;
is($res, '{"version":'~$Gamed::Engine::version~'"games":[]}');
