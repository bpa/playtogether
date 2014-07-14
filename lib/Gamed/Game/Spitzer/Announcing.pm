package Gamed::Game::Spitzer::Announcing;

use Gamed::Object;
use Gamed::Handler;
use parent 'Gamed::State';

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
    },
    schneider => sub {
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
