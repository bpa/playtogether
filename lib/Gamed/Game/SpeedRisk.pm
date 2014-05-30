package Gamed::Game::SpeedRisk;

use Gamed::Game::SpeedRisk::Themes;

use parent 'Gamed::Game';

on 'create' => sub {
    my ( $self, $player, $msg ) = @_;
    $self->{board}       = Gamed::Game::SpeedRisk::Board->new( $msg->{board} );
    $self->{countries}   = $self->{board}{territories};
    $self->{min_players} = 2;
    $self->{max_players} = $self->{board}{players};
    $self->change_state('WAITING_FOR_PLAYERS');
};

on 'join' => sub {
	my ($self, $player, $msg) = @_;
	$self->{themes}->player_joined($player);
};

on 'theme' => sub {
	my ($self, $player, $msg) = @_;
	$self->{themes}->change_theme($self, $player, $msg);
};

on 'quit' => sub {
	my ($self, $player, $msg) = @_;
	$self->{themes}->player_quit($player);
};

states {
    WAITING_FOR_PLAYERS => Gamed::State::WaitingForPlayers->new( next => 'PLACING' ),
    PLACING             => Gamed::Game::SpeedRisk::Placing->new(),
    PLAYING             => Gamed::Game::SpeedRisk::Playing->new(),
    GAME_OVER           => Gamed::State::GameOver->new(),
};

1;
