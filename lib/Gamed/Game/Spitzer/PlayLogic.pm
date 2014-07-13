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

    # Holding called ace

    # Following suit
    my $lead = suit( $trick->[0], $trump );
    return 1 if suit( $card, $trump ) eq $lead;

    # Sort cards into suits
    my %suit;
    for ( $hand->values ) {
        push @{ $suit{ suit($_) } }, $_;
    }

    # Must follow suit if held
    return if @{ $suit{$lead} };

    # Must play trump if not following suit
    return if @{ $suit{D} };

    # Don't have led suit or trump
    return 1;
}

sub suit {
    my ( $value, $suit ) = $_[0] =~ /(\d+)(\D)/;
    return 'D' if $value == 11 || $value == 12;    #J and Q are trump
    return $suit;
}

my %rank = (
    '12C' => 33,
    '7D'  => 32,
    '12S' => 31,
    '12H' => 30,
    '12D' => 29,
    '11C' => 28,
    '11S' => 27,
    '11H' => 26,
    '11D' => 25,
    1     => 5,
    10    => 4,
    13    => 3,
    9     => 2,
    8     => 1,
    7     => 0,
);

sub trick_winner {
    my ( $self, $trick, $game ) = @_;
    my $lead          = suit( $trick->[0] );
    my $winning_seat  = 0;
    my $winning_value = 0;
    for my $p ( 0 .. $#$trick ) {
        my ( $value, $suit );
        $value = $rank{$p};
        if ( !$value ) {
            ( $value, $suit ) = $trick->[$p] =~ /(\d+)(.)$/;
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
    1  => 11,
    10 => 10,
    13 => 4,
    12 => 3,
    11 => 2,
);

my %score = (
    normal                    => [ -42, -9,  -6,  3,   6,   9 ],
    schneider                 => [ -18, -15, -12, -9,  9,   12 ],
    stealer                   => [ -42, -9,  -6,  9,   12,  15 ],
    zola                      => [ -15, -12, -9,  18,  27,  36 ],
    'zola schneider'          => [ -42, -36, -24, -18, 36,  39 ],
    'zola schneider schwartz' => [ -42, -42, -39, -33, -27, 42 ],
);

sub on_round_end {
    my ( $self, $game ) = @_;
    delete $game->{public}{leader};

    my %taken;
    while ( my ( $id, $p ) = each %{ $game->{players} } ) {
        if ( exists $game->{calling_team}{$id} ) {
            for ( @{ $p->{taken} } ) {
                my ($v) = /(\d+).$/;
                $taken{cards}++;
                $taken{value} += $point_value{$v} || 0;
            }
        }
        delete $p->{taken};
        delete $p->{announcement};
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
        my $r = exists( $game->{calling_team}{$id} ) ? $result : -$result;
        $p->{public}{points} += $r;
        $msg->{$id}{change} = $r;
        $msg->{$id}{points} = $p->{public}{points};
    }

    delete $game->{calling_team};
    $game->broadcast( round => \%msg );

    my @players = sort { $a->{public}{points} <=> $b->{public}{points} } values %{ $game->{players} };
    if ( $players[0]{public}{points} >= 42 && $players[1]{public}{points} < $players[0]{public}{points} ) {
        $game->broadcast(
            final => { winner => $players[0]{id} );
              $game->change_state('GAME_OVER');
            } else {
            $game->change_state('DEALING');
        }
    }
}

1;
