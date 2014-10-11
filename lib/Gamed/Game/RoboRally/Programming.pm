package Gamed::Game::RoboRally::Programming;

use Gamed::Handler;
use Gamed::Object::Bag;
use List::Util qw/shuffle/;
use parent 'Gamed::State';

sub new {
    my ( $pkg, %opts ) = @_;
    bless { name => 'Programming', next => $opts{next} }, $pkg;
}

sub on_enter_state {
    my ( $self, $game ) = @_;

    $game->{movement_cards}->reset->shuffle;
    for my $p ( values %{ $game->{players} } ) {
		$p->{locked} = 0;
        my $cards = 9 - $p->{public}{damage};
        $p->{private}{cards} = Gamed::Object::Bag->new( $game->{movement_cards}->deal($cards) );
        $p->{client}->send( programming => { cards => $p->{private}{cards} } );
    }
}

on 'program' => sub {
    my ( $self, $player, $msg, $player_data ) = @_;
	my @cards;
    my $game = $self->{game};

	if ($player_data->{locked}) {
		$player->err('Registers are already programmed');
		return;
	}

	$msg->{lock} = 0 unless defined $msg->{lock};

	if (ref($msg->{registers}) ne 'ARRAY' || @{$msg->{registers}} > 5 ) {
		$player->err("Invalid program");
		return;
	}

	for my $r (@{$msg->{registers}}) {
		if (ref($r) ne 'ARRAY' || @$r > 1 ) {
			$player->err("Invalid program");
			return;
		}
		push @cards, @$r;
	}

	for my $c (@cards) {
		unless ($player_data->{private}{cards}->contains($c)) {
			$player->err("Invalid card");
			return;
		}
	}

	$player_data->{locked} = $msg->{lock};
	$player_data->{private}{registers} = $msg->{registers};
	$player->send( program => { lock => $msg->{lock}  } );
};

on 'quit' => sub {
    my ( $self, $player, $msg, $player_data ) = @_;
    my $game = $self->{game};
    delete $player_data->{client};
    $player_data->{public}{ready} = 1;
    my @remaining = grep { exists $_->{client} } values %{ $game->{players} };
    if ( @remaining == 1 ) {
        $game->broadcast( victory => { player => $remaining[0]->{public}{id} } );
        $game->change_state('GAME_OVER');
    }
    else {
        $game->change_state( $self->{next} )
          unless grep { !$_->{public}{ready} } values %{ $game->{players} };
    }
};

1;
