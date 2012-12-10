module Gamed::Network;

class INET {
	has IO::Socket $.sock;
	has IO::Socket @.clients;
	
	submethod new (Int $port) {
		self.bless(*, sock => IO::Socket::INET.new(:localhost('0.0.0.0'), :localport($port), :listen));
	}

	method poll() {
		if self.sock.poll(1,0) {
			self.clients.push(self.sock.accept());
		}
		for self.clients -> $c {
			if $c.poll(1,0) {
				$c.write($c.read(1024));
			}
		}
	}
}
