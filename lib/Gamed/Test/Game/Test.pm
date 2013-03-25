package Gamed::Test::Game::Test;

use parent 'Gamed::Game';

sub build {
    my $self = shift;
    my $opts = shift->{opts};
    $self->{seat}        = [ map { { name => $_ } } @{$opts->{seats}} ];
    $self->{state_table} = $opts->{state_table};
    $self->{state_table}{end} = Gamed::State->new;
    $self->change_state('start');
}

sub on_join {
    my ( $self, $player, $message ) = @_;
    push @{ $self->{players} }, $player;
}

1;
