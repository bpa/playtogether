package Gamed::Game::RoboRally;

our $DEV = 1;
use Gamed::Game::RoboRally::Decks;
use Gamed::Game::RoboRally::Course;
use Gamed::Game::RoboRally::Joining;
use Gamed::Game::RoboRally::Announcing;
use Gamed::Game::RoboRally::Programming;
use Gamed::Game::RoboRally::Executing;
use Gamed::Game::RoboRally::Cleanup;

use Gamed::Handler;
use parent 'Gamed::Game';

use Gamed::States {
    WAITING_FOR_PLAYERS => Gamed::Game::RoboRally::Joining->new,
    PROGRAMMING         => Gamed::Game::RoboRally::Programming->new,
    ANNOUNCING          => Gamed::Game::RoboRally::Announcing->new,
    EXECUTING           => Gamed::Game::RoboRally::Executing->new,
    CLEANUP             => Gamed::Game::RoboRally::Cleanup->new,
    GAME_OVER           => Gamed::State::GameOver->new,
};

on 'create' => sub {
    my ( $self, $player, $msg ) = @_;
    $msg->{course} ||= 'checkmate';
    $self->{public}{course} = Gamed::Game::RoboRally::Course->new( $msg->{course} );
    $self->{movement_cards} = Gamed::Game::RoboRally::Decks->new('movement');
    $self->{option_cards}   = Gamed::Game::RoboRally::Decks->new('options');
    $self->{option_cards}->reset->shuffle;
    $self->{min_players} = 2;
    $self->{max_players} = 8;

    $self->change_state('WAITING_FOR_PLAYERS');
};

on 'quit' => sub {
    my ( $self, $client, $msg, $player ) = @_;
    delete $self->{public}{bots}{ delete $player->{public}{bot} }{player} if $player->{public}{bot};
};

1;
