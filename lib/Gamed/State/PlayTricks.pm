package Gamed::State::PlayTricks;

use parent 'Gamed::State';

sub build {
    my ( $self, $next, $logic ) = @_;
    $self->{next}   = $next;
    $self->{logic}  = $logic;
}

1;
