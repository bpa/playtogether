package Gamed::Test::Game::HiLo;

use parent 'Gamed::Game';
use Gamed::Const;

sub build {
    my $self = shift;
    $self->{num}     = int( rand(101) );
    $self->{guesses} = 0;
}

sub on_message {
    my ( $self, $player, $message ) = @_;
    $self->{guesses}++;
    my $guess = $message->{guess};
    my %resp = ( cmd => 'game', guesses => $self->{guesses} );
    if ( $guess == $self->{num} ) {
        $resp{answer} = 'Correct!';
        $self->build;
    }
    else {
        $resp{answer} = $guess < $self->{num} ? 'Too low' : 'Too high';
    }
    $player->send( \%resp );
}

sub on_join {
	my ($self, $player, $message) = @_;
	die GAME_FULL() if exists $self->{joined};
	$self->{joined} = ();
}

1;
