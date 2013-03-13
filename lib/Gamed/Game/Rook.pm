package Gamed::Game::Rook;

use parent 'Gamed::Game';

sub on_create {
	my $self = shift;
	$self->{'max-players'} = 4;
	$self->change_state('WAITING_FOR_PLAYERS');
}

1;
