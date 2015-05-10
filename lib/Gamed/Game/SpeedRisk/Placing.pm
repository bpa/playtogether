package Gamed::Game::SpeedRisk::Placing;

use Gamed::Handler;
use parent 'Gamed::State';
use Gamed::NullPlayer;
use List::Util qw/shuffle/;
use Scalar::Util qw/looks_like_number/;

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
    my $armies  = int($countries / @players);
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
        $game->{public}{countries}[$i]{armies} = 1;
        $game->{public}{countries}[$i]{owner}  = $p->{public}{id};
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
            for my $c ( @{ $game->{public}{countries} } ) {
                if ( $c->{owner} eq 'd' ) {
                    $dummy->{private}{armies}--;
                    $c->{armies}++;
                    last unless $dummy->{private}{armies};
                }
            }
        }
    }

    $game->broadcast( placing => { countries => $game->{public}{countries} } );
}

on 'ready' => sub {
    my ( $self, $player, $message, $player_data ) = @_;
    my $game = $self->{game};
    $player_data->{public}{ready} = 1;
    $game->broadcast( ready => { player => $player->{in_game_id} } );
    $game->change_state( $self->{next} )
      unless grep { !$_->{public}{ready} } values %{ $game->{players} };
};

on 'not ready' => sub {
    my ( $self, $player, $message, $player_data ) = @_;
    my $game = $self->{game};
    $player_data->{public}{ready} = 0;
    $game->broadcast( 'not ready' => { player => $player->{in_game_id} } );
};

on 'place' => sub {
    my ( $self, $player, $message, $player_data ) = @_;
    my $game = $self->{game};
    $player->err("No country specified") && return
      unless looks_like_number( $message->{country} );
    my $c = $message->{country};
    $player->err("Invalid country") && return
      unless 0 <= $c && $c <= $#{ $game->{public}{countries} };

    my $country = $game->{public}{countries}[$c];
    $player->err("Not owner") && return
      unless $country->{owner} eq $player->{in_game_id};

    my $armies = int($message->{armies} || 0);
    $player->err("Invalid armies") && return
      unless looks_like_number($armies);
    $player->err("Not enough armies") && return
      unless 0 < $armies && $armies <= $player_data->{private}{armies};

    $country->{armies} += $armies;
    $player_data->{private}{armies} -= $armies;

    $player->send( armies => { armies => $player_data->{private}{armies} } );
    $game->broadcast( country => { country => { id => $c, armies => $country->{armies}, owner => $country->{owner} } } );
};

on 'quit' => sub {
    my ( $self, $player, $msg, $player_data ) = @_;
    my $game = $self->{game};
	delete $player_data->{client};
    $player_data->{public}{ready} = 1;
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
