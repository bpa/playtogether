package Gamed::Game::Spitzer::Announcing;

use Gamed::Object;
use Gamed::Handler;
use parent 'Gamed::State';
use Gamed::Game::Spitzer::PlayLogic;

sub new {
    my ( $pkg, %opts ) = @_;
    bless { name => 'Announcing', starting_player => 0 }, $pkg;
}

sub on_enter_state {
    my ( $self, $game ) = @_;
    $self->{announced}    = 0;
    $game->{calling_team} = [];
    delete $game->{public}{caller};
    delete $game->{public}{announcement};
    $self->{starting_player} = ++$self->{starting_player} % 4;
    $self->{player}          = $self->{starting_player};
    $game->{public}{player}  = $game->{seats}[ $self->{player} ];
    $game->broadcast( announcing => { player => $game->{public}{player} } );
}

sub on_leave_state {
    my ( $self, $game ) = @_;
    $game->{public}{player} = $game->{seats}[ $self->{starting_player} ];
    $game->broadcast(
        announcement => {
            announcement => $game->{public}{announcement},
            caller       => $game->{public}{caller},
            call         => $game->{public}{call} } );
}

sub solo {
    my ( $self, $player, $msg, $player_data ) = @_;
    my $game = $self->{game};
    $game->{type}                 = $msg->{announcement};
    $game->{calling_team}         = [ $player->{in_game_id} ];
    $game->{public}{announcement} = $msg->{announcement};
    $game->{public}{caller}       = $player->{in_game_id};
    $game->change_state('PLAYING');
}

my %action = (
    none => sub {
        my ( $self, $player, $msg, $player_data ) = @_;
        my $game = $self->{game};
        if ( ++$self->{announced} >= 4 ) {
            for my $p ( values %{ $game->{players} } ) {
                push @{ $game->{calling_team} }, $p->{id} if $p->{private}{cards}->contains('QC') || $p->{private}{cards}->contains('QS');
            }
            $game->{type} = @{ $game->{calling_team} } == 1 ? 'sneaker' : 'normal';
        	$game->{public}{announcement} = 'none';
            $game->change_state('PLAYING');
        }
        else {
            $self->{player} = ++$self->{player} % 4;
            $game->{public}{player} = $game->{seats}[ $self->{player} ];
            $game->broadcast( announcing => { player => $game->{public}{player} } );
        }
    },
    call => sub {
        my ( $self, $player, $msg, $player_data ) = @_;
        my $game = $self->{game};
        my $call = $msg->{call};
        my $hand = $player_data->{private}{cards};
		unless ($hand->contains('QC') && $hand->contains('QS')) {
			$player->err('Invalid call');
			return;
		}
        $game->{calling_team} = [ $player->{in_game_id} ];
        my ( $all_fail, %suit, %fail ) = 1;
        for my $c ( $hand->values ) {
            push @{ $suit{ Gamed::Game::Spitzer::PlayLogic->suit($c) } }, $c;
        }
        for my $s (qw/C H S/) {
            my $have_ace = $hand->contains("A$s");
            $all_fail = 0 unless $have_ace;
            $fail{$s} = exists $suit{$s} && !$have_ace;
        }
        if ( $call eq 'first' ) {
            if ( !$all_fail ) {
                $player->err("Invalid call");
                return;
            }
        }
        else {
            my ( $number, $suit ) = $call =~ /(.*)(.)$/;
            if ( $number ne 'A' || $hand->contains($call) ) {
                $player->err("Invalid call");
                return;
            }
        }
        $game->{type}                 = 'call';
        $game->{public}{announcement} = $msg->{call};
        $game->{public}{caller}       = $player->{in_game_id};
        $game->{public}{call}         = 'call';
        $game->change_state('PLAYING');
    },
    schneider => sub {
        my ( $self, $player, $msg, $player_data ) = @_;
        my $game = $self->{game};
        my ( @calling_team, $callers_team );
        for my $p ( values %{ $game->{players} } ) {
            my $team = ( $p->{cards}->contains('QC') || $p->{cards}->contains('QS') ) ? 1 : 0;
            push @{ $calling_team[$team] }, $p->{id};
            $callers_team = $team if $p->{id} eq $player->{in_game_id};
        }
        $game->{type}                 = 'schneider';
        $game->{calling_team}         = $calling_team[$callers_team];
        $game->{public}{announcement} = 'schneider';
        $game->{public}{caller}       = $player->{in_game_id};
        $game->change_state('PLAYING');
    },
    zola                      => \&solo,
    'zola schneider'          => \&solo,
    'zola schneider schwartz' => \&solo,
);

on 'announce' => sub {
    my ( $self, $player, $msg, $player_data ) = @_;
    my $game = $self->{game};
    if ( $player->{in_game_id} ne $game->{public}{player} ) {
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
