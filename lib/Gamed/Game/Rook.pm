package Gamed::Game::Rook;

use Moose;
use namespace::clean;

extends qw/Gamed::Game/;

sub BUILD {
    my $self = shift;
    $self->{points}      = [ 0, 0 ];
    $self->{seats}       = [qw/n e s w/];
    $self->{state_table} = {
        WAITING_FOR_PLAYERS => Gamed::State::WaitingForPlayers->new(next => 'DEALING'),
        DEALING             => Gamed::State::Dealing->new(
            next => 'BIDDING',
            deck => Gamed::Object::Deck::Rook->new('partnership'),
            deal => { seat => 10, nest => 5 },
        ),
        BIDDING => Gamed::State::Bidding->new(
            next  => 'DECLARING',
            min   => 100,
            max   => 200,
            valid => sub { $_[0] % 5 == 0 }
        ),
        DECLARING => Gamed::Game::Rook::Declaring->new(
            name => 'Declaring',
            next => 'PLAYING'
        ),
        PLAYING   => Gamed::State::PlayTricks->new( logic => Gamed::Game::Rook::PlayLogic->new ),
        GAME_OVER => Gamed::State->new( name              => 'Game Over' ),
    };
    $self->change_state('WAITING_FOR_PLAYERS');
}

__PACKAGE__->meta->make_immutable;
