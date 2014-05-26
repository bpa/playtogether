package Gamed::Test::Game::HiLo;

use parent 'Gamed::Game';
use Gamed::Const;
use Moose;
use namespace::autoclean;

has 'num' => (
	is => 'rw',
	isa => 'Int',
);

has 'guesses' => (
	is => 'rw',
	isa => 'Int',
	default => 0,
);

sub BUILD {
    my $self = shift;
    $self->{num} = int( rand(101) );
}

sub on_message {
    my ( $self, $player, $message ) = @_;
    $self->{guesses}++;
    my $guess = $message->{guess};
    my %resp = ( guesses => $self->{guesses} );
    if ( $guess == $self->{num} ) {
        $resp{answer} = 'Correct!';
        $self->{num} = int( rand(101) );
		$self->{guesses} = 0;
    }
    else {
        $resp{answer} = $guess < $self->{num} ? 'Too low' : 'Too high';
    }
    $player->send( 'game', \%resp );
}

before 'on_join' => sub {
    my ($self, $player) = @_;
    die GAME_FULL() if keys %{ $self->{players} };
};

__PACKAGE__->meta->make_immutable;
