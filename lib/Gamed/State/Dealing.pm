package Gamed::State::Dealing;

use strict;
use warnings;
use Scalar::Util 'looks_like_number';

use parent 'Gamed::State';

sub build {
    my ( $self, $opts ) = @_;
    $self->{next} = $opts->{next};
    $self->{deck} = $opts->{deck};
    if (looks_like_number($opts->{deal})) {
        $self->{deal} = { seat => $opts->{deal} };
    }
    else {
        $self->{deal} = $opts->{deal};
    }
    $self->{dealer} = 0;
}

sub on_message {
    my ( $self, $game, $client, $msg ) = @_;
    if ( $client->{id} eq $game->{players}[$self->{dealer}]{id} ) {
        $game->change_state( $self->{next} );
    }
    else {
        $client->send( { cmd => 'err', reason => 'Not your turn' } );
    }
}

sub on_leave_state {
    my ( $self, $game ) = @_;
    $self->{deck}->reset->shuffle;
    
    while (my ($k, $num) = each(%{$self->{deal}})) {
        if ($k eq 'seat') {
            my $seats = @{$game->{seat}} - 1;
            for my $s ( 0 .. $seats ) {
                my $cards = [$self->{deck}->deal($num)];
                $game->{seat}[$s]{cards} = $cards;
                $game->{players}[$s]->send( { cmd => 'game', action => 'deal', hand => $cards } );
            }
        }
        else {
            $game->{$k} = [$self->{deck}->deal($num)];
        }
    }
    $self->{dealer}++;
    $self->{dealer} = 0 if $self->{dealer} >= @{$game->{seat}};
}

1;
