package Gamed::Game::RoboRally::Setup;

use Gamed::Handler;
use List::Util qw/shuffle/;

use Gamed::Handler;
use parent 'Gamed::State';

sub new {
    my ( $pkg, %opts ) = @_;
    bless { name => 'Setup', next => $opts{next} }, $pkg;
}

sub on_enter_state {
    my ($self, $game) = @_;

	for my $p ( values %{ $game->{players} } ) {
		$p->{public}{damage} = 0;
	}

    $game->change_state( $self->{next} );
}

1;
