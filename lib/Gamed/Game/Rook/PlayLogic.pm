package Gamed::Game::Rook::PlayLogic;

sub new { return bless {}, shift }

sub is_valid_play {
	my ($self, $card, $trick, $hand) = @_;
	return unless $hand->contains($card);

	if (@$trick == 0) {
		return 1;
	}

	my $lead = substr $trick->[0], -1;
	return 1 if substr $card, -1 eq $lead;

	for ($hand->values) {
		return if substr $_, -1 eq $lead;
	}
	
	return 1;
}

1;
