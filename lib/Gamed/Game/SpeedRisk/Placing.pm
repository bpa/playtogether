package Gamed::Game::SpeedRisk::Placing;

use v5.14;
use Moose;
use Gamed::NullPlayer;
use List::Util qw/shuffle/;
use namespace::autoclean;

extends 'Gamed::State';

has '+name' => ( default => 'Placing' );
has 'next' => ( default => 'PLAYING', is => 'bare' );

use Data::Dumper;

sub on_enter_state {
    my ( $self, $game ) = @_;

    my $countries = @{ $game->{board}{territories} };

    my $dummy;
    if ( keys %{ $game->{players} } == 2 ) {
        $dummy = { in_game_id => 'd', client => Gamed::NullPlayer->new };
        $game->{players}{d} = $dummy;
    }

    my @players = values %{ $game->{players} };
    my $armies  = $countries / @players;
    $armies++ unless $countries % @players == 0;

    for my $p (@players) {
        $p->{ready}          = 0;
        $p->{armies}         = $armies;
        $p->{countries} = 0;
    }

    #Give out countries in a random, but equal way
    my $player_ind = 0;
    my @indexes    = shuffle( 0 .. $countries - 1 );
    for my $i (@indexes) {
        my $p = $players[$player_ind];
        $game->{countries}[$i]{armies} = 1;
        $game->{countries}[$i]{owner}  = $p->{in_game_id};
        $p->{armies}--;
        $p->{countries}++;
        $player_ind = ++$player_ind % @players;
    }

    #For those who didn't get as many countries, start with 2 more armies
    for my $p (@players) {
        $p->{armies} *= 2;
        $p->{armies} += $game->{board}{starting_armies}[$#players];
        $p->{client}->send( { cmd => 'armies', armies => $p->{armies} } );
    }

    #Spread out the dummy player's armies so the countries aren't effectively free
    if ( defined $dummy ) {
		$dummy->{ready} = 1;
        while ( $dummy->{armies} ) {
            for my $c ( @{ $game->{countries} } ) {
                if ( $c->{owner} eq 'd' ) {
                    $dummy->{armies}--;
                    $c->{armies}++;
                    last unless $dummy->{armies};
                }
            }
        }
    }

    $game->broadcast(
        { cmd => 'state', state => 'Placing', countries => $game->{countries} } );

}

sub on_message {
    my ( $self, $game, $player, $message ) = @_;
    for ( $message->{cmd} ) {
        when ('ready') {
            $player->{ready} = 1;
            $game->broadcast( { cmd => 'ready', player => $player->{in_game_id} } );
            $game->change_state( $self->{next} )
              unless grep { !$_->{ready} } values %{ $game->{players} };
        }
    }
}

sub on_leave_state {
}

__PACKAGE__->meta->make_immutable;
