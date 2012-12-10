module Gamed::Network;

class INET {
	has IO::Socket::INET $.sock;
	
	method new (Int $port) {
		self.bless(*, sock => IO::Socket::INET.new(:localhost('0.0.0.0'), :localport($port), :listen));
	}

	method poll() {
		my \c = $.sock.accept();
		note c;
		c.send(c.recv);
	}
}
