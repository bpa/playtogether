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
    my $self = shift;
    my $game = $self->{game};

    $game->change_state( $self->{next} );
}

1;
