package Gamed::Game::SpeedRisk;

use File::Basename;
use File::Spec::Functions 'catdir';
use Gamed::Handler;
use Gamed::Game::SpeedRisk::Placing;
use Gamed::Game::SpeedRisk::Playing;

use Gamed::Handler;
use parent 'Gamed::Game';

use Gamed::States {
    WAITING_FOR_PLAYERS => Gamed::State::WaitingForPlayers->new( next => 'PLACING' ),
    PLACING             => Gamed::Game::SpeedRisk::Placing->new( next => 'PLAYING' ),
    PLAYING             => Gamed::Game::SpeedRisk::Playing->new( next => 'GAME_OVER' ),
    GAME_OVER           => Gamed::State::GameOver->new,
};

on 'create' => sub {
    my ( $self, $player, $msg ) = @_;
    $msg->{board} ||= 'Classic';
    $self->{board}                = Gamed::Game::SpeedRisk::Board->new( $msg->{board} );
    $self->{public}{countries}    = $self->{board}{territories};
    $self->{min_players}          = 3;
    $self->{max_players}          = $self->{board}{players};
    $self->{public}{rules}{board} = $msg->{board};
    opendir( my $dh, catdir( $Gamed::public, "g", "SpeedRisk", $msg->{board} ) );

    for my $file ( grep { !/^\./ && !/^board\./ && /\.json$/ } readdir($dh) ) {
        $self->{public}{themes}{ substr( $file, 0, -5 ) } = ();
    }
    closedir($dh);
    $self->change_state('WAITING_FOR_PLAYERS');
};

on 'join' => sub {
    my ( $self, $player, $msg ) = @_;
	my @available = grep { not defined $self->{public}{themes}{$_} } keys %{ $self->{public}{themes} };
    my $theme = $available[ rand @available ];
    $self->{public}{themes}{$theme} = $player->{in_game_id};
    $self->{players}{ $player->{in_game_id} }{public}{theme} = $theme;
};

on 'theme' => sub {
    my ( $self, $player, $msg ) = @_;
    if (   $msg->{theme}
        && exists $self->{public}{themes}{ $msg->{theme} }
        && !defined $self->{public}{themes}{ $msg->{theme} } )
    {
        $self->{public}{themes}{ $self->{players}{ $player->{in_game_id} }{public}{theme} } = ();
        $self->{public}{themes}{ $msg->{theme} }                                            = $player->{in_game_id};
        $self->{players}{ $player->{in_game_id} }{public}{theme}                            = $msg->{theme};
        $self->broadcast( theme => { theme => $msg->{theme}, player => $player->{in_game_id} } );
    }
    else {
        $player->err("Invalid theme");
    }
};

on 'quit' => sub {
    my ( $self, $client, $msg, $player ) = @_;
    $self->{public}{themes}{ delete $player->{public}{theme} } = ();
};

1;
