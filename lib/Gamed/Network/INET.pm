module Gamed::Network;

class INET {
	has IO::Socket $!sock;
	
	submethod new (Int $port) {
		self.bless(*, sock => IO::Socket::INET.new(:localhost('0.0.0.0'), :localport($port), :listen));
	}

	method poll() {
	}
}
