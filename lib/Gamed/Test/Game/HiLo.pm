package Gamed::Game::Test::HiLo;

use parent 'Gamed::Game';

sub on_create {
    my $self = shift;
    $self->{num}     = int( rand(101) );
    $self->{guesses} = 0;
}

sub on_message {
    my ( $self, $player, $message ) = @_;
    $self->{guesses}++;
    my $guess = $message->{guess};
    my %resp = ( guesses => $self->{guesses} );
    if ( $guess == $self->{num} ) {
        $resp{answer} = 'Correct!';
		$self->on_create;
    }
    else {
        $resp{answer} = $guess < $self->{num} ? 'Too low' : 'Too high';
    }
    $player->send( \%resp );
}

sub on_join {
    die 'Game full' if scalar( shift->{players} );
}

1;
