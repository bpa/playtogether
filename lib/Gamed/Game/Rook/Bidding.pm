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
	if ($client->{id} ne $game->{players}[$self->{bidder}]{id}) {
		$client->err('Not your turn');
	}
    elsif (!defined $msg->{bid}) {
        $client->err('No bid given');
    }
    elsif ($msg->{bid} < 100) {
        $client->err('Bidding starts at 100');
    }
    elsif ($msg->{bid} > 200) {
        $client->err('Max bid is 200');
    }
    else {
        $game->broadcast($msg);
    }
}

1;
