package Gamed::Game::RoboRally;

our $DEV = 1;
use Gamed::Game::RoboRally::Decks;
use Gamed::Game::RoboRally::Course;
use Gamed::Game::RoboRally::Joining;
use Gamed::Game::RoboRally::Programming;
use Gamed::Game::RoboRally::Executing;

use Gamed::Handler;
use parent 'Gamed::Game';

use Gamed::States {
    WAITING_FOR_PLAYERS => Gamed::Game::RoboRally::Joining->new,
    PROGRAMMING         => Gamed::Game::RoboRally::Programming->new,
    EXECUTING           => Gamed::Game::RoboRally::Executing->new,
    GAME_OVER           => Gamed::State::GameOver->new,
};

on 'create' => sub {
    my ( $self, $player, $msg ) = @_;
    $msg->{course} ||= 'checkmate';
    $self->{public}{course} = Gamed::Game::RoboRally::Course->new( $msg->{course} );
	$self->{movement_cards} = Gamed::Game::RoboRally::Decks->new('movement');
    $self->{min_players}    = 2;
    $self->{max_players}    = 8;

    $self->change_state('WAITING_FOR_PLAYERS');
};

on 'quit' => sub {
    my ( $self, $client, $msg, $player ) = @_;
    delete $self->{public}{bots}{ delete $player->{public}{bot} }{player};
};

1;
