package Gamed::Game::SpeedRisk::Themes;

use File::Find;
use File::Basename;
use File::Spec::Functions 'catdir';

sub new {
    my %themes;
    find sub {
        if ( $_ eq 'theme.properties' ) {
            $themes{ basename($File::Find::dir) } = ();
        }
    }, catdir($Gamed::public, "g", "SpeedRisk", "themes");
    return \%themes;
}

sub player_joined {
    my ( $self, $player ) = @_;

    my $unused = $self->{themes};
    my $theme  = ( keys %$unused )[ rand keys %$unused ];
    delete $unused->{$theme};
    $player->{public}{theme} = $theme;
};

sub change_theme {
    my ( $self, $game, $player, $message ) = @_;
	if ( defined $message->{theme} && exists $self->{themes}{ $message->{theme} } ) {
		$self->{themes}{ $player->{public}{theme} } = ();
		$player->{public}{theme} = $message->{theme};
		delete $self->{themes}{ $message->{theme} };
		$game->broadcast( theme => { theme => $message->{theme}, player => $player->{in_game_id} } );
	}
	else {
		$player->{client}->err("Invalid theme");
	}
};

sub player_quit {
    my ( $self, $player ) = @_;
    $self->{themes}{ delete $player->{public}{theme} } = ();
};

1;
