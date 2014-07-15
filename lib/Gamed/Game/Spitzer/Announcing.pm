package Gamed::Game::Spitzer::Announcing;

use Gamed::Object;
use Gamed::Handler;
use parent 'Gamed::State';
use Gamed::Game::Spitzer::PlayLogic;

sub new {
    my ( $pkg, %opts ) = @_;
    bless { name => 'Announcing' }, $pkg;
}

sub on_enter_state {
    my ( $self, $game ) = @_;
    $self->{announced}    = 0;
    $game->{calling_team} = [];
    delete $game->{public}{caller};
    delete $game->{public}{announcement};
}

sub solo {
    my ( $self, $player, $msg, $player_data ) = @_;
    my $game = $self->{game};
    $game->{type}                 = $msg->{announcement};
    $game->{calling_team}         = [ $player->{in_game_id} ];
    $game->{public}{announcement} = $msg->{announcement};
    $game->{public}{caller}       = $player->{in_game_id};
    $game->broadcast( announce => { announcement => $msg->{announcement}, caller => $player->{in_game_id} } );
    $game->change_state('PLAYING');
}

my %action = (
    none => sub {
        my ( $self, $player, $msg, $player_data ) = @_;
        my $game = $self->{game};
        if ( ++$self->{announced} >= 4 ) {
            for my $p ( values %{ $game->{players} } ) {
                push @{ $game->{calling_team} }, $p->{id} if $p->{cards}->contains('QC') || $p->{cards}->contains('QS');
            }
            $game->{type} = @{ $game->{calling_team} } == 1 ? 'sneaker' : 'normal';
            $game->broadcast('announce');
            $game->change_state('PLAYING');
        }
    },
    call => sub {
        my ( $self, $player, $msg, $player_data ) = @_;
		my $game = $self->{game};
		my $call = $msg->{call};
		$game->{calling_team} = [ $player->{in_game_id} ];
		if ($call ne 'first') {
			my $hand = $player_data->{private}{cards};
			my %suit = map { $_ => Gamed::Object::Bag()->new() } qw/C H S D/;
			for my $c ($hand->{values}) {
				push @{$suit{Gamed::Game::Spitzer::PlayLogic->suit($c)}}, $c;
			}
			my ($number, $suit) = $call =~ /(.*)(.)$/;
			if ($number ne 'A' || $hand->contains($call) || ) {
				$player->err("Invalid call");
				return;
			}
		}
		$game->{type} = 'call';
    	$game->{public}{announcement} = $msg->{call};
    	$game->{public}{caller}       = $player->{in_game_id};
		$game->broadcast('announce' => { announcement => 'call', call => $call, caller => $player->{in_game_id} } );
		$game->change_state('PLAYING');
    },
    schneider => sub {
        my ( $self, $player, $msg, $player_data ) = @_;
		my $game = $self->{game};
		my (@calling_team, $callers_team);
		for my $p ( values %{ $game->{players} } ) {
			my $team = ($p->{cards}->contains('QC') || $p->{cards}->contains('QS')) ? 1 : 0;
			push @{$calling_team[$team]}, $p->{id};
			$callers_team = $team if $p->{id} eq $player->{in_game_id};
		}
		$game->{type}                 = 'schneider';
		$game->{calling_team} = $calling_team[$callers_team];
		$game->{public}{announcement} = 'schneider';
		$game->{public}{caller}       = $player->{in_game_id};
		$game->broadcast( announce => { announcement => 'schneider', caller => $player->{in_game_id} } );
		$game->change_state('PLAYING');
    },
    zola                      => \&solo,
    'zola schneider'          => \&solo,
    'zola schneider schwartz' => \&solo,
);

on 'announce' => sub {
    my ( $self, $player, $msg, $player_data ) = @_;
    my $game = $self->{game};
    if ( $player->{in_game_id} ne $game->{public}{bidder} ) {
        $player->err('Not your turn');
        return;
    }

    my $f = $action{ $msg->{announcement} };
    if ($f) {
        $f->( $self, $player, $msg, $player_data );
    }
    else {
        $player->err('Invalid announcement');
    }
};

1;
