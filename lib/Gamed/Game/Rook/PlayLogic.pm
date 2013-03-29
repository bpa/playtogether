package Gamed::Game::Rook::PlayLogic;

sub new { return bless {}, shift }

sub is_valid_play {
    my ( $self, $card, $trick, $hand ) = @_;
    return unless $hand->contains($card);

    if ( @$trick == 0 ) {
        return 1;
    }

    my $lead = substr $trick->[0], -1;
    return 1 if substr( $card, -1 ) eq $lead;

    for ( $hand->values ) {
        return if substr( $_, -1 ) eq $lead;
    }

    return 1;
}

sub trick_winner {
    my ($self, $trick, $game) = @_;
    my $lead = substr $trick->[0], -1;
    my $winning_seat = 0;
    my $winning_value = 0;
    for my $p (0 .. $#$trick) {
        my ($value, $suit) = $trick->[$p] =~ /(\d+)(.)$/;
        $suit = $game->{trump} if $suit eq '_';
        $value = 0 unless $suit eq $lead || $suit eq $game->{trump};
        $value = 15 if $value == 1;
        $value += 20 if $suit eq $game->{trump};
        if ($value > $winning_value) {
            $winning_seat = $p;
            $winning_value = $value;
        }
    }
    return $winning_seat;
}

1;
