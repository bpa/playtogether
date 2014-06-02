package Gamed::Game::Rook;

use Gamed::Handler;
use Gamed::Game::Rook::Declaring;
use Gamed::Game::Rook::PlayLogic;

use parent 'Gamed::Game';

use Gamed::States {
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
	GAME_OVER => Gamed::State::GameOver->new,
};

on 'create' => sub {
    my ($self, $player, $msg) = @_;
    $self->{points}      = [ 0, 0 ];
    $self->{seats}       = [qw/n e s w/];
	$self->change_state('WAITING_FOR_PLAYERS');
};

on 'status' => sub {
    my ($self, $player, $msg) = @_;
	$player->send(status => { player => $player->{private}, status => $self->{public} } );
};

1;
