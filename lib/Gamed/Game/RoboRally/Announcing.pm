package Gamed::Game::RoboRally::Announcing;

use Gamed::Handler;
use parent 'Gamed::State';

sub new {
    my ( $pkg, %opts ) = @_;
    bless { name => 'Announcing' }, $pkg;
}

sub on_enter_state {
    my ( $self, $game ) = @_;
    $game->change_state('EXECUTING')
}

on 'announce' => sub {
    my ( $self, $player, $msg, $player_data ) = @_;
    my $game = $self->{game};
};

1;
