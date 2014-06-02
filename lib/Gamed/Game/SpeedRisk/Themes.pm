package Gamed::Game::SpeedRisk::Themes;

use File::Find;
use File::Basename;
use File::Spec::Functions 'catdir';

sub new {
	my ($pkg, $board) = @_;
    my %themes;
    find sub {
        if ( $_ eq 'theme.properties' ) {
            $themes{ basename($File::Find::dir) } = ();
        }
    }, catdir($Gamed::public, "g", "SpeedRisk", $board, "themes");
    return bless \%themes, $pkg;
}

sub player_joined {
    my ( $self, $player ) = @_;

    my $theme  = ( keys %$self )[ rand keys %$self ];
    delete $self->{$theme};
    $player->{public}{theme} = $theme;
};

sub change_theme {
    my ( $self, $game, $player, $message ) = @_;
	if ( exists $self->{ $message->{theme} } ) {
		$self->{ $player->{public}{theme} } = ();
		$player->{public}{theme} = $message->{theme};
		delete $self->{ $message->{theme} };
		$game->broadcast( theme => { theme => $message->{theme}, player => $player->{in_game_id} } );
	}
	else {
		$player->{client}->err("Invalid theme");
	}
};

sub player_quit {
    my ( $self, $player ) = @_;
    $self->{ delete $player->{public}{theme} } = ();
};

1;
