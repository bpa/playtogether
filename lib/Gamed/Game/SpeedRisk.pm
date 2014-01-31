package Gamed::Game::SpeedRisk;

use Moose;
use Moose::Util qw( apply_all_roles );
use Gamed::Themes;
use namespace::autoclean;

extends qw/Gamed::Game/;

sub BUILD {
    my ( $self, $args ) = @_;
	$self->{board} = Gamed::Game::SpeedRisk::Board->new( variant => 'ClassicRisk' );
    $self->{min_players} = 2;
    $self->{max_players} = $self->{board}{players};
    $self->{state_table} = {
        WAITING_FOR_PLAYERS => Gamed::State::WaitingForPlayers->new('PLACING'),
        PLACING             => Gamed::Game::SpeedRisk::Placing->new(),

        #        PLAYING             => Gamed::Game::SpeedRisk::Playing->new(),
        #        RUNNING             => Gamed::Game::SpeedRisk::Running->new(),
        GAME_OVER => Gamed::State->new({ name => 'Game Over' }),
    };
    apply_all_roles( $self->{state_table}{WAITING_FOR_PLAYERS}, 'Gamed::Themes' );
    apply_all_roles( $self->{state_table}{PLACING},             'Gamed::Themes' );
    $self->change_state('WAITING_FOR_PLAYERS');
}

__PACKAGE__->meta->make_immutable;
