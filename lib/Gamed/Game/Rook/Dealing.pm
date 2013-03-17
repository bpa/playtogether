package Gamed::Game::Rook::Dealing;

use strict;
use warnings;

use parent 'Gamed::State::Dealing';

sub build {
    my $self = shift;
    $self->{deck}   = Gamed::Object::Deck::Rook->new('partnership');
    $self->{dealer} = -1;
	$self->{next_state} = 'BIDDING';
}

sub on_leave_state {
    my ( $self, $game ) = @_;
	$game->{leader} = $self->{dealer};
    $self->{deck}->reset->shuffle;
    $game->{nest} = [ $self->{deck}->deal(5) ];
    for my $s ( 0 .. 3 ) {
        my $cards = [ $self->{deck}->deal(10) ];
        $game->{seat}[$s]{cards} = $cards;
        $game->{players}[$s]->send( { cmd => 'game', action => 'deal', hand => $cards } );
    }
}

1;
