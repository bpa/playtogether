package Gamed::Test::Game::Test;

use Gamed::Handler;
use parent 'Gamed::Game';

on 'create' => sub {
    my ( $self, $player, $opts ) = @_;
    while ( my ( $k, $v ) = each %$opts ) {
        $self->{$k} = $v;
    }
    $self->change_state('start');
};

1;
