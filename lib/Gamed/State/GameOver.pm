package Gamed::State::GameOver;

use parent 'Gamed::State';

sub new {
	return bless { name => 'GameOver' }, shift;
}

sub on_enter_state {
    my $self = shift;
    #TODO: set timer to destroy game
}

1;
