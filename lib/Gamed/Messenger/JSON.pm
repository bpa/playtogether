use v6;

use Gamed::Messenger;

class Gamed::Messenger::JSON is Gamed::Messenger {
	use JSON::Tiny;
	sub serialize(%msg) {
		return to-json(%msg);
	}

	sub deserialize(Buf $buf) {
		return from-json($buf);
	}

	sub accepts(Buf $buf) {
		return $buf[0] ~~ '{';
	}
}
