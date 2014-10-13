package Gamed::Game::RoboRally::Executing;

use Gamed::Handler;
use parent 'Gamed::State';

sub new {
    my ( $pkg, %opts ) = @_;
    bless { name => 'Executing' }, $pkg;
}

sub on_enter_state {
    my ($self, $game) = @_;

	for my $p ( values %{ $game->{players} } ) {
		$p->{public}{ready} = 0;
	}

	$self->{register} = 0;
	$self->{results} = [];
	execute();
}

1;
