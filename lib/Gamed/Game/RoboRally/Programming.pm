package Gamed::Game::RoboRally::Programming;

use Gamed::Handler;
use Gamed::Object::Bag;
use List::Util qw/shuffle/;
use parent 'Gamed::State';

sub new {
    my ( $pkg, %opts ) = @_;
    bless { name => 'Programming' }, $pkg;
}

sub on_enter_state {
    my ( $self, $game ) = @_;

    $game->{movement_cards}->reset->shuffle;
    for my $p ( values %{ $game->{players} } ) {
		if ($p->{public}{lives} > 0) {
			$p->{public}{ready} = 0;
			my $cards = 9 - $p->{public}{damage};
			$p->{private}{cards} = Gamed::Object::Bag->new( $game->{movement_cards}->deal($cards) );
		}
		else {
			$p->{public}{ready} = 1;
			$p->{private}{cards} = Gamed::Object::Bag->new();
		}
		$p->{private}{registers} = [];
		$p->{client}->send( programming => { cards => $p->{private}{cards} } );
    }
}

on 'program' => sub {
    my ( $self, $player, $msg, $player_data ) = @_;
	my @cards;
    my $game = $self->{game};

	if ($player_data->{ready}) {
		$player->err('Registers are already programmed');
		return;
	}

	if (ref($msg->{registers}) ne 'ARRAY' || @{$msg->{registers}} > 5 ) {
		$player->err("Invalid program");
		return;
	}

	for my $i ( 0 .. 4 ) {
		last unless defined $msg->{registers}[$i];
		my $r = $msg->{registers}[$i];
		if (ref($r) ne 'ARRAY' 
		|| locked_but_not_matching( $i, $r, $player_data )
		|| @$r > 1 ) {
			$player->err("Invalid program");
			return;
		}
		push @cards, @$r unless $player_data->{public}{locked}[$i];
	}

	for my $c (@cards) {
		unless ($player_data->{private}{cards}->contains($c)) {
			$player->err("Invalid card");
			return;
		}
	}
	
	$player_data->{private}{registers} = $msg->{registers};
	$player->send( 'program' => { registers => $msg->{registers} });
};

on ready => sub {
    my ( $self, $player, $msg, $player_data ) = @_;
    my $game = $self->{game};

	if (grep ( @$_ > 0, @{$player_data->{private}{registers}}) != 5) {
    	$player->err('Programming incomplete');
		return;
	}

    $player_data->{public}{ready} = 1;
    $game->broadcast( ready => { player => $player->{in_game_id} } );
    $game->change_state('EXECUTING')
    	unless grep { !$_->{public}{ready} } values %{ $game->{players} };
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
        $game->change_state( 'EXECUTING' )
          unless grep { !$_->{public}{ready} } values %{ $game->{players} };
    }
};

sub locked_but_not_matching {
	my ($i, $register, $player_data) = @_;
	return unless $player_data->{public}{locked}[$i];

	my $locked = $player_data->{public}{registers}[$i];

	return 1 unless @$register == @$locked;
	for my $j ( 0 .. $#$register ) {
		return 1 unless $register->[$j] eq $locked->[$j];
	}

	return;
}

sub handle_time_up {
	my ($self, $game) = @_;

	for my $p ( values %{$game->{players}} ) {
		next if $p->{ready};

		my $cards = Gamed::Object::Bag->new($p->{private}{cards}->values);
		for my $i ( 0 .. 4) {
			$cards->remove($p->{private}{registers}[$i]) unless $p->{public}{locked}[$i];
		}

		my @available = shuffle $cards->values;
		for my $i ( 0 .. 4 ) {
			$p->{private}{registers}[$i] ||= [];
			my $r = $p->{private}{registers}[$i];
			if (@$r == 0) { 
				if ($p->{public}{locked}[$i]) {
					push @$r, @{$p->{public}{registers}[$i]};
				}
				else {
					push @$r, shift @available;
				}
			}
		}
	}
}

1;
