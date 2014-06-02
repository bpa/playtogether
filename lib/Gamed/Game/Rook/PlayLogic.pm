package Gamed::Game::Rook::PlayLogic;

sub new { bless {}, shift; }

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
    my ( $self, $trick, $game ) = @_;
    my $lead          = substr $trick->[0], -1;
    my $winning_seat  = 0;
    my $winning_value = 0;
    for my $p ( 0 .. $#$trick ) {
        my ( $value, $suit ) = $trick->[$p] =~ /(\d+)(.)$/;
        $suit = $game->{trump} if $suit eq '_';
        $value = 0 unless $suit eq $lead || $suit eq $game->{trump};
        $value = 15 if $value == 1;
        $value += 20 if $suit eq $game->{trump};
        if ( $value > $winning_value ) {
            $winning_seat  = $p;
            $winning_value = $value;
        }
    }
    return $winning_seat;
}

my %point_value = (
    0  => 20,
    1  => 15,
    14 => 10,
    10 => 10,
    5  => 5,
);

sub on_round_end {
    my ( $self, $game ) = @_;
    my @points = (0,0);
    my @cards_taken = (0,0);
    my $team = $game->{bidder} % 2;
    for my $s ( 0 .. 3 ) {
        my $t = $s % 2;
        for ( @{ $game->{seat}[$s]{taken} } ) {
            my ($v) = /(\d+).$/;
            $points[$t] += $point_value{$v};
            $cards_taken[$t]++;
        }
    }
    my $bonus = $cards_taken[0] == $cards_taken[1] ? $team : $cards_taken[0] > $cards_taken[1] ? 0 : 1;
    $points[$bonus] += 20;
    if ( $points[$team] < $game->{bid} ) {
        $points[$team] = -1 * $game->{bid};
    }
    $game->{points}[0] += $points[0];
    $game->{points}[1] += $points[1];
    if ( $game->{points}[0] != $game->{points}[1] && ( $game->{points}[0] >= 500 || $game->{points}[1] >= 500 ) ) {
        $game->change_state('GAME_OVER');
    }
    else {
        $game->change_state('DEALING');
    }
}

1;
