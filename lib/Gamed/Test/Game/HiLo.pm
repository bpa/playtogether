package Gamed::Test::Game::HiLo;

use Gamed::Handler;
use parent 'Gamed::Game';

on 'create' => sub {
	my ($game, $player, $msg) = @_;
	$game->{guesses} = 0;
	$game->{number} = int(rand(100)) + 1;
};

before 'join' => sub {
	my ($game, $player, $msg) = @_;
	die "Game full" if keys %{ $game->{players} };
};

on 'guess' => sub {
	my ($game, $player, $msg) = @_;
	my %res = ( guesses => ++$game->{guesses} );
	if ( $msg->{guess} == $game->{number} ) {
		$res{answer} = 'Correct!';
		$game->{number} = int( rand(101) ) + 1;
		$game->{guesses} = 0;
	}
	else {
		$res{answer} = $msg->{guess} < $game->{number} ? 'Too low' : 'Too high';
	}
	$player->send('guess', \%res);
};

1;
