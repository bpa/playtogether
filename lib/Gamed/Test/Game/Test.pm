package Gamed::Test::Game::Test;

use parent 'Gamed::Game';

sub build {
    my $self = shift;
    my $opts = shift->{opts};
    $self->{seat}        = [ map { { name => $_ } } @{delete $opts->{seats}} ];
	while (my ($k,$v) = each %$opts) {
		$self->{$k} = $v;
	}
    $self->{state_table}{end} = Gamed::State->new;
    $self->change_state('start');
}

sub on_join {
    my ( $self, $player, $message ) = @_;
    push @{ $self->{players} }, $player;
}

1;
