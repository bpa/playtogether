package Gamed::Game::Spitzer::PlayLogic;

use strict;
use warnings;

sub new { bless {}, shift; }

sub is_valid_play {
    my ( $self, $card, $trick, $hand, $game ) = @_;
    return unless $hand->contains($card);

    # Can lead any card
    if ( @$trick == 0 ) {
        return 1;
    }

    my $lead = $self->suit( $trick->[0] );

    # Holding called ace rules
    if ( $game->{called} && $hand->contains( $game->{called} ) ) {
        return    # Must play if suit led
          if $card ne $game->{called}
              && $self->suit( $game->{called} ) eq $lead
              && !exists $game->{state}{suits_led}{$lead};

        return    # Can't slough
          if $card eq $game->{called}
              && $self->suit( $game->{called} ) ne $lead
              && $hand->values > 1;
    }

    # Following suit
    return 1 if $self->suit($card) eq $lead;

    # Sort cards into suits
    my %suit;
    for ( $hand->values ) {
        push @{ $suit{ $self->suit($_) } }, $_;
    }

    # Must follow suit if held
    return if defined $suit{$lead};

    # Must play trump if not following suit
    return if $self->suit($card) ne 'D' && defined $suit{D};

    # Don't have led suit or trump
    return 1;
}

sub suit {
    my ( $value, $suit ) = $_[1] =~ /(.+)(.)$/;
    return 'D' if $value eq 'J' || $value eq 'Q';    #J and Q are trump
    return $suit;
}

my %rank = (
    'QC' => 33,
    '7D' => 32,
    'QS' => 31,
    'QH' => 30,
    'QD' => 29,
    'JC' => 28,
    'JS' => 27,
    'JH' => 26,
    'JD' => 25,
    A    => 5,
    10   => 4,
    K    => 3,
    9    => 2,
    8    => 1,
    7    => 0,
);

sub trick_winner {
    my ( $self, $trick, $game ) = @_;
    my $lead          = $self->suit( $trick->[0] );
    my $winning_seat  = 0;
    my $winning_value = 0;
    for my $p ( 0 .. $#$trick ) {
        my ( $value, $suit );
        $value = $rank{ $trick->[$p] };
        if ( !$value ) {
            ( $value, $suit ) = $trick->[$p] =~ /(.+)(.)$/;
            $value = $rank{$value};
            if ( $suit eq 'D' ) {
                $value += 20;
            }
            elsif ( $suit eq $lead ) {
                $value += 10;
            }
        }
        if ( $value > $winning_value ) {
            $winning_seat  = $p;
            $winning_value = $value;
        }
    }
    return $winning_seat;
}

my %point_value = (
    A  => 11,
    10 => 10,
    K  => 4,
    Q  => 3,
    J  => 2,
);

my %score = (
    normal                    => [ -42, -9,  -6,  3,   6,   9 ],
    schneider                 => [ -18, -15, -12, -9,  9,   12 ],
    sneaker                   => [ -42, -9,  -6,  9,   12,  15 ],
    zola                      => [ -15, -12, -9,  18,  27,  36 ],
    'zola schneider'          => [ -42, -36, -24, -18, 36,  39 ],
    'zola schneider schwartz' => [ -42, -42, -39, -33, -27, 42 ],
);

sub on_round_end {
    my ( $self, $game ) = @_;
    delete $game->{public}{leader};

    my %taken = ( cards => 0, value => 0 );
    for my $id ( @{ $game->{calling_team} } ) {
        for ( @{ $game->{players}{$id}{taken} } ) {
            my ($v) = /(.+).$/;
            $taken{cards}++;
            $taken{value} += $point_value{$v} || 0;
        }
    }

    for my $p ( values %{ $game->{players} } ) {
        delete $p->{taken};
    }

    my $result =
        $taken{cards} == 32 ? $score{ $game->{type} }[5]
      : $taken{cards} == 0  ? $score{ $game->{type} }[0]
      : $taken{value} <= 30 ? $score{ $game->{type} }[1]
      : $taken{value} <= 60 ? $score{ $game->{type} }[2]
      : $taken{value} < 90  ? $score{ $game->{type} }[3]
      :                       $score{ $game->{type} }[4];

    my %msg;
    while ( my ( $id, $p ) = each %{ $game->{players} } ) {
        if ( grep( $_ eq $id, @{ $game->{calling_team} } ) && $result > 0 ) {
            $p->{public}{points} += $result;
            $msg{$id}{change} = $result;
        }
        elsif ( !grep( $_ eq $id, @{ $game->{calling_team} } ) && $result < 0 ) {
            $p->{public}{points} -= $result;
            $msg{$id}{change} = -$result;
        }
        $msg{$id}{points} = $p->{public}{points};
    }

    delete $game->{calling_team};
    $game->broadcast( round => \%msg );

    my @players = sort { $b->{public}{points} <=> $a->{public}{points} } values %{ $game->{players} };
    if ( $players[0]{public}{points} >= 42 && $players[1]{public}{points} < $players[0]{public}{points} ) {
        $game->broadcast( final => { winner => $players[0]{id} } );
        $game->change_state('GAME_OVER');
    }
    else {
        $game->change_state('DEALING');
    }
}

1;
