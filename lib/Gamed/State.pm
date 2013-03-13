package Gamed::State;

sub new {
	my ($pkg, $game) = @_;
	my $self = bless {}, $pkg;
	$self->on_enter($game);
}

sub on_enter_state {
}

sub on_message {
}

sub on_leave_state {
}

sub on_join {
}

sub on_quit {
}

1;
