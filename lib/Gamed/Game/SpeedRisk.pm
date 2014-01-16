package Gamed::Game::SpeedRisk;

use parent qw/Gamed::Game/;

sub build {
    my $self = shift;
	$self->{seat} = [ {}, {}, {} ];
    $self->{state_table} = {
        WAITING_FOR_PLAYERS => Gamed::State::WaitingForPlayers->new('PLACING'),
        PLACING             => Gamed::State->new,
		#PLACING             => Gamed::Game::SpeedRisk::Placing->new(),
        #        PLAYING             => Gamed::Game::SpeedRisk::Playing->new(),
        #        RUNNING             => Gamed::Game::SpeedRisk::Running->new(),
        GAME_OVER => Gamed::State->new,
    };
    $self->change_state('WAITING_FOR_PLAYERS');
}

1;
