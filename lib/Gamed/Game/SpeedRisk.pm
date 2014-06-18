package Gamed::Game::SpeedRisk;

use File::Find;
use File::Basename;
use File::Spec::Functions 'catdir';
use Gamed::Handler;
use Gamed::Game::SpeedRisk::Playing;
use Gamed::Game::SpeedRisk::Placing;

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
    $self->{board}       = Gamed::Game::SpeedRisk::Board->new( $msg->{board} );
    $self->{countries}   = $self->{board}{territories};
    $self->{min_players} = 2;
    $self->{max_players} = $self->{board}{players};
    find sub {
        if ( $_ eq 'theme.properties' ) {
            $self->{themes}{ basename($File::Find::dir) } = ();
        }
    }, catdir($Gamed::public, "g", "SpeedRisk", $msg->{board}, "themes");
    $self->change_state('WAITING_FOR_PLAYERS');
};

on 'join' => sub {
	my ($self, $player, $msg) = @_;
    my $theme = ( keys %{$self->{themes}} )[ rand keys %{$self->{themes}} ];
    delete $self->{themes}{$theme};
    $self->{players}{$player->{in_game_id}}{public}{theme} = $theme;
};

on 'theme' => sub {
	my ($self, $player, $msg) = @_;
	if ( $msg->{theme} && exists $self->{themes}{ $msg->{theme} } ) {
		$self->{themes}{ $self->{players}{$player->{in_game_id}}{public}{theme} } = ();
		$self->{players}{$player->{in_game_id}}{public}{theme} = $msg->{theme};
		delete $self->{themes}{ $msg->{theme} };
		$self->broadcast( theme => { theme => $msg->{theme}, player => $player->{in_game_id} } );
	}
	else {
		$player->err("Invalid theme");
	}
};

on 'quit' => sub {
	my ($self, $player, $msg) = @_;
    $self->{themes}{ delete $self->{players}{$player->{in_game_id}}{public}{theme} } = ();
};

1;
