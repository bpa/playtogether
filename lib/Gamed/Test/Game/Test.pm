package Gamed::Test::Game::Test;

use parent 'Gamed::Game';

sub build {
    my ( $self, $opts ) = @_;
    while ( my ( $k, $v ) = each %$opts ) {
        $self->{$k} = $v;
    }
    $self->{state_table}{waiting} = Gamed::State::WaitingForPlayers->new('start');
    $self->{state_table}{end}     = Gamed::State->new;
    $self->change_state('waiting');
}

1;
