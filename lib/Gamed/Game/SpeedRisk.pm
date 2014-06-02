package Gamed::Game::SpeedRisk;

use File::Find;
use File::Basename;
use File::Spec::Functions 'catdir';
use Gamed::Handler;
use Gamed::Game::SpeedRisk::Playing;
use Gamed::Game::SpeedRisk::Placing;

use parent 'Gamed::Game';

use Gamed::States {
    WAITING_FOR_PLAYERS => Gamed::State::WaitingForPlayers->new( next => 'PLACING' ),
    PLACING             => Gamed::Game::SpeedRisk::Placing->new( next => 'PLAYING' ),
    PLAYING             => Gamed::Game::SpeedRisk::Playing->new( next => 'GAME_OVER' ),
    GAME_OVER           => Gamed::State::GameOver->new,
};

on 'create' => sub {
    my ( $self, $player, $msg ) = @_;
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
    $player->{public}{theme} = $theme;
};

on 'theme' => sub {
	my ($self, $player, $msg) = @_;
	if ( exists $self->{themes}{ $message->{theme} } ) {
		$self->{themes}{ $player->{public}{theme} } = ();
		$player->{public}{theme} = $message->{theme};
		delete $self->{themes}{ $message->{theme} };
		$game->broadcast( theme => { theme => $message->{theme}, player => $player->{in_game_id} } );
	}
	else {
		$player->{client}->err("Invalid theme");
	}
};

on 'quit' => sub {
	my ($self, $player, $msg) = @_;
    $self->{themes}{ delete $player->{public}{theme} } = ();
};

1;
