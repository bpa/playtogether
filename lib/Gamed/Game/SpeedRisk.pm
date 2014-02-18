package Gamed::Game::SpeedRisk;

use Moose;
use Moose::Util qw( apply_all_roles );
use Gamed::Game::SpeedRisk::Themes;
use namespace::autoclean;

extends qw/Gamed::Game/;

sub BUILD {
    my ( $self, $args ) = @_;
    $self->{board} = Gamed::Game::SpeedRisk::Board->new( variant => 'Classic' );
    $self->{countries} = $self->{board}{territories};
    $self->{min_players} = 2;
    $self->{max_players} = $self->{board}{players};
    $self->{state_table} = {
        WAITING_FOR_PLAYERS => Gamed::State::WaitingForPlayers->new( next => 'PLACING'),
        PLACING             => Gamed::Game::SpeedRisk::Placing->new(),
        PLAYING             => Gamed::Game::SpeedRisk::Playing->new(),
        GAME_OVER           => Gamed::State::GameOver->new(),
    };
    apply_all_roles(
        $self->{state_table}{WAITING_FOR_PLAYERS},
        'Gamed::Game::SpeedRisk::Themes'
    );
    apply_all_roles( $self->{state_table}{PLACING},
        'Gamed::Game::SpeedRisk::Themes' );
    $self->change_state('WAITING_FOR_PLAYERS');
}

__PACKAGE__->meta->make_immutable;
