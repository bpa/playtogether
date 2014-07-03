package Gamed::Game::Rook::PlayLogic;

sub new { bless {}, shift; }

sub is_valid_play {
    my ( $self, $card, $trick, $hand, $game ) = @_;
    return unless $hand->contains($card);

    if ( @$trick == 0 ) {
        return 1;
    }

    my $trump = $game->{public}{trump};
    my $lead = suit( $lead, $trump );
    return 1 if suit( $card, $trump ) eq $lead;

    for ( $hand->values ) {
        return if suit( $card, $trump ) eq $lead;
    }

    return 1;
}

sub suit {
    my $s = substr( $_[0], -1 );
    return $s eq '_' ? $_[1] : $s;
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
    my @points      = ( 0, 0 );
    my @cards_taken = ( 0, 0 );
    my $team;
	for my $s ( 0 .. $#{$game->{seats}} ) {
		$team = $s % 2 if $game->{seats}[$s] eq $game->{public}{bidder};
	}
    for my $s ( 0 .. 3 ) {
        my $t = $s % 2;
		my $seat = $game->{seats}[$s];
        for ( @{ $game->{players}{$seat}{taken} } ) {
            my ($v) = /(\d+).$/;
            $points[$t] += $point_value{$v};
            $cards_taken[$t]++;
        }
    }
    my $bonus = $cards_taken[0] == $cards_taken[1] ? $team : $cards_taken[0] > $cards_taken[1] ? 0 : 1;
    $points[$bonus] += 20;
	print $game->{public}{bidder}, " bid ", $game->{public}{bid}, " in ", $game->{public}{trump}, " and got ", $points[$team], "\n";
	printf("NS: %4i EW: %4i\n", $points[0], $points[1]);
    if ( $points[$team] < $game->{public}{bid} ) {
        $points[$team] = -1 * $game->{public}{bid};
    }
    $game->{public}{points}[0] += $points[0];
    $game->{public}{points}[1] += $points[1];
	print "Currently ", $game->{public}{points}[0], " to ", $game->{public}{points}[1], "\n";
    if ( $game->{public}{points}[0] != $game->{public}{points}[1]
        && ( $game->{public}{points}[0] >= 500 || $game->{public}{points}[1] >= 500 ) )
    {
		my $final = $game->{public}{points};
		$game->broadcast( final => { winner => $final->[0] > $final->[1] ? 'NS' : 'EW' } );
        $game->change_state('GAME_OVER');
    }
    else {
        $game->change_state('DEALING');
    }
}

1;
