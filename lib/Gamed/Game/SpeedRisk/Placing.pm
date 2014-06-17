package Gamed::Game::SpeedRisk::Placing;

use Gamed::Handler;
use Gamed::NullPlayer;
use List::Util qw/shuffle/;
use Gamed::Game::SpeedRisk::Place;

use Gamed::Handler;
use parent 'Gamed::State';

sub new {
    my ( $pkg, %opts ) = @_;
    bless { name => 'Placing', next => $opts{next} }, $pkg;
}

sub on_enter_state {
    my $self = shift;
    my $game = $self->{game};

    my $countries = @{ $game->{board}{territories} };

    my $dummy;
    if ( keys %{ $game->{players} } == 2 ) {
        $dummy = { public => { id => 'd' }, client => Gamed::NullPlayer->new };
        $game->{players}{d} = $dummy;
    }

    my @players = values %{ $game->{players} };
    my $armies  = $countries / @players;
    $armies++ unless $countries % @players == 0;

    for my $p (@players) {
        $p->{public}{ready}   = 0;
        $p->{private}{armies} = $armies;
        $p->{countries}       = 0;
    }

    #Give out countries in a random, but equal way
    my $player_ind = 0;
    my @indexes    = shuffle( 0 .. $countries - 1 );
    for my $i (@indexes) {
        my $p = $players[$player_ind];
        $game->{countries}[$i]{armies} = 1;
        $game->{countries}[$i]{owner}  = $p->{public}{id};
        $p->{private}{armies}--;
        $p->{countries}++;
        $player_ind = ++$player_ind % @players;
    }

    #For those who didn't get as many countries, start with 2 more armies
    for my $p (@players) {
        $p->{private}{armies} *= 2;
        $p->{private}{armies} += $game->{board}{starting_armies}[$#players];
        $p->{client}->send( armies => { armies => $p->{private}{armies} } );
    }

    #Spread out the dummy player's armies so the countries aren't effectively free
    if ( defined $dummy ) {
        $dummy->{ready} = 1;
        while ( $dummy->{private}{armies} ) {
            for my $c ( @{ $game->{countries} } ) {
                if ( $c->{owner} eq 'd' ) {
                    $dummy->{private}{armies}--;
                    $c->{armies}++;
                    last unless $dummy->{private}{armies};
                }
            }
        }
    }

    $game->broadcast( state => { state => 'Placing', countries => $game->{countries} } );

}

on 'ready' => sub {
    my ( $self, $player, $message, $player_data ) = @_;
    my $game = $self->{game};
    $player_data->{public}{ready} = 1;
    $game->broadcast( ready => { player => $player->{in_game_id} } );
    $game->change_state( $self->{next} )
      unless grep { !$_->{public}{ready} } values %{ $game->{players} };
};

on 'place' => \&Gamed::Game::SpeedRisk::Place::on_place;

on 'quit' => sub {
    my ( $self, $player, $msg, $player_data ) = @_;
    my $game = $self->{game};
    delete $player_data->{client};
    $game->{players}{ $player->{in_game_id} }{public}{ready} = 1;
    my @remaining = grep { exists $_->{client} } values %{ $game->{players} };
    if ( @remaining == 1 ) {
        $game->broadcast( victory => { player => $remaining[0]->{public}{id} } );
        $game->change_state('GAME_OVER');
    }
    else {
        $game->change_state( $self->{next} )
          unless grep { !$_->{public}{ready} } values %{ $game->{players} };
    }
};

1;
