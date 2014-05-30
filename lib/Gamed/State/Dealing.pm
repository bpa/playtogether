package Gamed::State::Dealing;

use Scalar::Util 'looks_like_number';
use Gamed::Object;

use Gamed::Handler;
use parent 'Gamed::State';

sub new {
    my ( $pkg, $self ) = @_;
	bless $self, $pkg;

	$self->{name} ||= 'Dealing';
	die "No next given\n" unless $self->{next};
	die "No deck given\n" unless $self->{deck}->isa('Gamed::Object::Deck');

    if ( looks_like_number( $self->{deal} ) ) {
        $self->{deal} = { seat => $self->{deal} };
    }
    else {
        $self->{deal} = $opts->{deal};
    }
    $self->{dealer} = 0;
	return $self;
}

sub on_enter_state {
    my $self = shift;
    $self->{game}->broadcast( dealing => { dealer => $self->{dealer} } );
}

sub on_leave_state {
    my $self = shift;
	my $game = $self->{game};

    $self->{deck}->reset->shuffle;

    while ( my ( $k, $num ) = each( %{ $self->{deal} } ) ) {
        if ( $k eq 'seat' ) {
            my $seats = scalar( keys %{ $game->{players} }) - 1;
            for my $s ( 0 .. $seats ) {
                my $cards = bag( $self->{deck}->deal($num) );
                $game->{players}{$s}{cards} = $cards;
                $game->{players}{$s}{client}->send( game => { action => 'deal', hand => [ $cards->values ] });
            }
        }
        else {
            $game->{$k} = bag( $self->{deck}->deal($num) );
        }
    }
    $self->{dealer}++;
    $self->{dealer} = 0 if $self->{dealer} >= keys %{ $game->{players} };
    $game->{leader} = $self->{dealer};
}

on 'deal' => sub {
    my ( $self, $player, $msg ) = @_;
    if ( $player->{in_game_id} eq $self->{dealer} ) {
        $self->{game}->change_state( $self->{next} );
    }
    else {
        $player->{client}->err('Not your turn');
    }
};

1;
