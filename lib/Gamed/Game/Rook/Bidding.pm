package Gamed::Game::Rook::Bidding;

use parent 'Gamed::State';

sub on_enter_state {
	my ($self, $game) = @_;
	$game->{bid} = 0;
	for (@{$game->{seats}}) {
		delete $_->{bid};
	}
	$self->{bidder} = $game->{leader};
}

sub on_message {
	my ($self, $game, $client, $msg) = @_;
	if ($client->{id} ne $game->{seats}[$self->{bidder}]{id}) {
		$client->send({ cmd=>'err', reason=>'Not your turn'});
		return;
	}
}

1;
