package Gamed::Game::Rook;

use parent qw/Gamed::Game/;

sub build {
    my $self = shift;
    $self->{seats} = 4;
    $self->{seat} = [map { { name => $_ } } ( 'n', 'e', 's', 'w' )];
    $self->{state_table} = {
        WAITING_FOR_PLAYERS => Gamed::State::FillSeats->new('DEALING'),
        DEALING             => Gamed::Game::Rook::Dealing->new,
        BIDDING             => Gamed::State::Bidding->new( {
              next  => 'PICKING_TRUMP',
              min   => 100,
              max   => 200,
              valid => sub { $_[0] % 5 == 0 }
            }
        ),

        #PICKING_TRUMP => Gamed::State::PickingTrump->new('PLAYING'),
        #PLAYING => Gamed::State::PlayTricks->new('SCORING'),
        #SCORING => Gamed::Game::Rook::Scoring->new,
        #FINISHED => Gamed::State::GameOver->new,
    };
    $self->change_state('WAITING_FOR_PLAYERS');
}

1;
