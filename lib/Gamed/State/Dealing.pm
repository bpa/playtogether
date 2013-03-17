package Gamed::State::Dealing;

use parent 'Gamed::State';

sub build {
    my ( $self, $deck, $next_state ) = @_;
    $self->{deck} = $deck;
	$self->{dealer} = -1;
	$self->{next_state} = $next_state;
}

sub on_enter_state {
	my ($self, $game) = @_;
	$self->{dealer}++;
	$self->{dealer} = 0 if $self->{dealer} >= $game->{seats};
}

sub on_message {
	my ($self, $game, $client, $msg) = @_;
	if ($client->{id} eq $game->{players}[$self->{dealer}]{id}) {
		$game->change_state($self->{next_state});
	}
	else {
		$client->send({ cmd=>'err', reason=>'Not your turn'});
	}
}

sub on_leave_state {
	my ($self, $game) = @_;
	$game->{leader} = $self->{dealer};
	
}

1;
