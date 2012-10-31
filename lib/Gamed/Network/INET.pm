module Gamed::Network;

class INET {
	has IO::Socket $sock;
	has IO::Socket @clients;
	
	submethod new (Int $port) {
		self.bless(*, sock => IO::Socket::INET.new(:localhost('0.0.0.0'), :localport($port), :listen));
	}

	method poll() {
		if $sock.poll(1,0) {
			@clients.push($sock.accept());
		}
		for @clients -> $c {
			if $c.poll(1,0) {
				$c.write($c.read());
			}
		}
	}
}
