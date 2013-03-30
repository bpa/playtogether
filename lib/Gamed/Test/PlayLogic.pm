package Gamed::Test::PlayLogic;

use strict;
use warnings; 

sub new { return bless {}, shift }

sub is_valid_play {
    my ( $self, $card, $trick, $hand ) = @_;
    return unless $hand->contains($card);
	my $min = 100;
	for ($hand->values) {
		$min = $_ if $_ < $min;
	}
	return $card == $min;
}

sub trick_winner {
    my ($self, $trick, $game) = @_;
    my $winning_seat = 0;
    my $winning_value = 0;
    for my $p (0 .. $#$trick) {
        if ($trick->[$p] > $winning_value) {
            $winning_seat = $p;
            $winning_value = $trick->[$p];
        }
    }
    return $winning_seat;
}

1;
