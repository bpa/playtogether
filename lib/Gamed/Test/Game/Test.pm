package Gamed::Test::Game::Test;

use Gamed::Handler;
use parent 'Gamed::Game';

use Gamed::State {
    start => Gamed::State::WaitingForPlayers->new( next => 'end' ),
    end   => Gamed::State::GameOver->new,
};

on 'create' => sub {
    my ( $self, $player, $opts ) = @_;
    while ( my ( $k, $v ) = each %$opts ) {
        $self->{$k} = $v;
    }
    $self->change_state('start');
};

1;
