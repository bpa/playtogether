package Gamed::Game::Rook;

use parent qw/Gamed::Game/;

sub build {
	my $self = shift;
	$self->{seats} = 4;
	$self->{state_table} = {
		WAITING_FOR_PLAYERS => Gamed::State::FillSeats->new(4, 'DEALING'),
		DEALING => Gamed::Game::Rook::Dealing->new,
		BIDDING => Gamed::Game::Rook::Bidding->new,
		#PICKING_TRUMP => Gamed::State::PickingTrump->new('PLAYING'),
		#PLAYING => Gamed::State::PlayTricks->new('SCORING'),
		#SCORING => Gamed::Game::Rook::Scoring->new,
		#FINISHED => Gamed::State::GameOver->new,
	};
	$self->change_state('WAITING_FOR_PLAYERS');

}

1;
