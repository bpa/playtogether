package Gamed::Game::SpeedRisk::Playing;

use v5.14;
use Moose;
use AnyEvent;
require Gamed::Game::SpeedRisk::Placing;
use namespace::autoclean;

extends 'Gamed::State';

has '+name' => ( default => 'Playing' );
has 'next' => ( default => 'GAME_OVER', is => 'bare' );

sub on_enter_state {
    my ( $self, $game ) = @_;
    $game->broadcast( { cmd => 'state', state => 'Playing' } );
    $self->{timer} = AE::timer $game->{board}{army_generation_period}, 0, sub {
        $self->generate_armies($game);
    };
}

sub on_message {
    my ( $self, $game, $player, $message ) = @_;
    for ( $message->{cmd} ) {
        when ("move") {
            $self->do_move( $game, $player, $message );
        }
        when ("place") {
            Gamed::Game::SpeedRisk::Placing::on_message( $self, $game, $player, $message );
        }
        default {
            $player->{client}->err('Invalid command');
        }
    }
}

sub generate_armies {
    my ( $self, $game ) = @_;
    if ( $game->{board}{army_generation_period} > 15 ) {
        $game->{board}{army_generation_period}--;
    }
    $self->{timer} = AE::timer $game->{board}{army_generation_period}, 0, sub {
        $self->generate_armies($game);
    };
    $game->broadcast(
        {
            cmd     => 'army timer',
            seconds => $game->{board}{army_generation_period}
        }
    );

    for my $p ( values %{ $game->{players} } ) {
        if ( $p->{countries} ) {
            if ( $p->{countries} > 11 ) {
                $p->{armies} += int( $p->{countries} / 3 );
            }
            else {
                $p->{armies} += 3;
            }

            #for my $c ( values %{ $game->{board}{continents} } ) {
            while (my ($name, $c) = each %{ $game->{board}{continents} } ) {
                my $holds_region = 1;
                for my $t ( @{ $c->{territories} } ) {
                    if ( $t->{owner} != $p->{in_game_id} ) {
                        $holds_region = 0;
                        last;
                    }
                }
                $p->{armies} += $c->{bonus} if $holds_region;
            }
            $p->{client}->send( { cmd => 'armies', armies => $p->{armies} } );
        }
    }
}

sub do_move {
    my ( $self, $game, $player, $message ) = @_;
    my $f = $message->{from};
    my $t = $message->{to};
    my $a = $message->{armies};
    if (   !defined $f
        || !defined $t
        || $f < 0
        || $t < 0
        || $f > $game->{countries}
        || $t > $game->{countries}
        || !$game->{countries}[$f]{borders}[$t] )
    {
        $player->{client}->err("Invalid destination");
        return;
    }

    my $from = $game->{countries}[$f];
    my $to   = $game->{countries}[$t];
    if ( $from->{owner} != $player->{in_game_id} ) {
        $player->{client}->err("Not owner");
        return;
    }

    if ( !$a || $a >= $from->{armies} ) {
        $player->{client}->err("Not enough armies");
        return;
    }

    if ( $to->{owner} == $player->{in_game_id} ) {
        $from->{armies} -= $a;
        $to->{armies} += $a;
		send_update( $game, $from, $to, 'move' );
    }
    else {
        do_attack( $game, $from, $to, $a );
    }
}

sub send_update {
	my ($game, $from, $to, $cmd) = @_;
    my @update;
    for my $c ( $from, $to ) {
        push @update,
          { owner   => $c->{owner},
            country => $c->{id},
            armies  => $c->{armies} };
    }
    $game->broadcast( { cmd => $cmd, result => \@update } );
}

sub do_attack {
    my ( $game, $from, $to, $armies ) = @_;

    my $defender = $game->{players}{ $to->{owner} };
    my $attacker = $game->{players}{ $from->{owner} };

    my @attack
      = sort { $b <=> $a } map { int( rand(6) ) } 1 .. ( $armies > 3 ? 3 : $armies );
    my @defend
      = sort { $b <=> $a } map { int( rand(6) ) } 1 .. ( $to->{armies} > 1 ? 2 : 1 );

    for my $die ( 0 .. ( @attack < @defend ? $#attack : $#defend ) ) {
        if ( $attack[$die] > $defend[$die] ) {
            $to->{armies}--;
        }
        else {
            $from->{armies}--;
            $armies--;
        }
    }

    unless ( $to->{armies} ) {
        $defender->{countries}--;
        $attacker->{countries}++;
        $to->{owner}  = $from->{owner};
        $to->{armies} = $armies;
        $from->{armies} -= $armies;
    }

    send_update( $game, $from, $to, 'attack' );

    unless ( $defender->{countries} ) {
        $game->broadcast( { cmd => 'defeated', player => $defender->{in_game_id} } );
    }
    if ( $attacker->{countries} == @{ $game->{countries} } ) {
        $game->broadcast(
            { cmd => 'Game Over', victor => $attacker->{in_game_id} } );
		$game->change_state('GAME_OVER');
    }
}

sub on_leave_state {
    my ( $self, $game ) = @_;
    undef $self->{timer};
}

sub on_quit {
    my ( $self, $game, $player ) = @_;
    $player->{ready} = 1;
    my @remaining = grep { exists $_->{client} } values %{ $game->{players} };
    if ( @remaining == 1 ) {
        $game->broadcast(
            { cmd => 'victory', player => $remaining[0]->{in_game_id} } );
        $game->change_state('GAME_OVER');
    }
}

__PACKAGE__->meta->make_immutable;
