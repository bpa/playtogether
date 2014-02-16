package Gamed::Game::SpeedRisk::Playing;

use v5.14;
use Moose;
use AnyEvent;
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

    for my $p ( @{ $game->{players} } ) {
        if ( $p->{countries} ) {
            if ( $p->{countries} > 11 ) {
                $p->{armies} += int( $p->{countries} / 3 );
            }
            else {
                $p->{armies} += 3;
            }
            for my $c ( @{ $game->{board}{continents} } ) {
                my $holds_region = 1;
                for my $t ( @{ $c->{territories} } ) {
                    if ( $game->{countries}[$t]{owner} != $p->{in_game_id} ) {
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

sub on_leave_state {
    my ( $self, $game ) = @_;
    undef $self->{timer};
}

__PACKAGE__->meta->make_immutable;
