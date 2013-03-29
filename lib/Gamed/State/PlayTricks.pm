package Gamed::State::PlayTricks;

use parent 'Gamed::State';

sub build {
    my ( $self, $next, $logic ) = @_;
    $self->{next}   = $next;
    $self->{logic}  = $logic;
}

sub on_enter_state {
    my ($self, $game) = @_;
    $self->{active_player} = $game->{bidder};
}

sub on_message {
    my ( $self, $game, $client, $msg ) = @_;
    if ( $client->{id} ne $game->{players}[ $self->{active_player} ]{id} ) {
        $client->err('Not your turn');
        return;
    }

    my $seat = $game->{seat}[ $self->{active_player} ];
    if ($self->{logic}->is_valid_play($msg->{play}, $self->{trick}, $seat->{cards}, $game)) {
        push @{$self->{trick}}, $msg->{play};
        $seat->{cards}->remove($msg->{play});
        $game->broadcast( { player => $seat->{name}, play => $msg->{play} } );
    }
    else {
        $client->err('Invalid card');
    }
}

1;
