package Gamed::Game::SpeedRisk::Placing;

use Moose;
use namespace::autoclean;

extends 'Gamed::State';

has '+name' => ( default => 'Placing' );

sub on_enter_state {
    my ( $self, $game ) = @_;
    my @countries;

    #if (keys %{$self->{players}})
    $game->broadcast(
        { cmd => 'state', state => 'Placing', countries => \@countries } );
}

sub on_message {
}

sub on_leave_state {
}

__PACKAGE__->meta->make_immutable;
