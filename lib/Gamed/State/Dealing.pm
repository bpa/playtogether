package Gamed::State::Dealing;

use Scalar::Util 'looks_like_number';
use Gamed::Object;

use Gamed::Handler;
use parent 'Gamed::State';

sub new {
    my ( $pkg, %opts ) = @_;
    my $self = bless \%opts, $pkg;

    $self->{name} ||= 'Dealing';
    $self->{dealer} = 0;
    die "No next given\n" unless $self->{next};
    die "No deck given\n" unless $self->{deck}->isa('Gamed::Object::Deck');

    if ( looks_like_number( $self->{deal} ) ) {
        $self->{deal} = { seat => $self->{deal} };
    }
    else {
        $self->{deal} = $opts{deal};
    }
    return $self;
}

sub on_enter_state {
    my ( $self, $game ) = @_;
    $self->{seats} = $game->{seats} || [ 0 .. keys %{ $game->{players} } ];
    $game->{public}{dealer} = $self->{seats}[ $self->{dealer} ];
    $game->broadcast( dealing => { dealer => $self->{seats}[ $self->{dealer} ] } );
}

sub on_leave_state {
    my ( $self, $game ) = @_;

    $self->{deck}->reset->shuffle;

    while ( my ( $k, $num ) = each( %{ $self->{deal} } ) ) {
        if ( $k eq 'seat' ) {
            for my $p ( values %{ $game->{players} } ) {
                my $cards = bag( $self->{deck}->deal($num) );
                $p->{private}{cards} = $cards;
                $p->{client}->send( deal => { cards => [ $cards->values ] } ) if $p->{client};
            }
        }
        else {
            $game->{$k} = bag( $self->{deck}->deal($num) );
        }
    }
    my $seats = $game->{seats} ? $game->{seats} : [ keys %{ $game->{players} } ];
    $self->{dealer} = ++$self->{dealer} % @{ $self->{seats} };
    $game->{leader} = $self->{dealer};
}

on 'deal' => sub {
    my ( $self, $player, $msg ) = @_;
    if ( $player->{in_game_id} eq $self->{seats}[ $self->{dealer} ] ) {
        $self->{game}->change_state( $self->{next} );
    }
    else {
        $player->err('Not your turn');
    }
};

1;
