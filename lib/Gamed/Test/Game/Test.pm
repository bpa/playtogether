package Gamed::Test::Game::Test;

use parent 'Gamed::Game';

sub build {
    my $self = shift;
    my $opts = shift->{opts};
	while (my ($k,$v) = each %$opts) {
		$self->{$k} = $v;
	}
    for (0 .. $#{$opts->{seats}}) {
        $self->{seat}[$_]{name} = $opts->{seats}[$_];
    }
    $self->{state_table}{waiting} = Gamed::State::WaitingForPlayers->new('start');
    $self->{state_table}{end} = Gamed::State->new;
    $self->change_state('waiting');
}

1;
