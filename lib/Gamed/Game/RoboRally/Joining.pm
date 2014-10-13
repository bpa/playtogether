package Gamed::Game::RoboRally::Joining;

use Gamed::Handler;
use parent 'Gamed::State';

use Gamed::State::WaitingForPlayers;
use File::Basename;
use File::Spec::Functions 'catdir';
use File::Slurp;
use JSON::Any;

sub new {
	bless { name => 'Joining' }, shift;
}

sub on_enter_state {
    my ( $self, $game ) = @_;
    $self->{min} = 2;
    $self->{max} = 8;

    my $json = JSON::Any->new;
    my $dir = catdir( $Gamed::public, "g", "RoboRally", "bots" );
    opendir( my $dh, $dir );
    for my $file ( grep { !/^\./ && /\.json$/ } readdir($dh) ) {
        eval {
            my $data = $json->decode( read_file( catdir( $dir, $file ) ) );
            $game->{public}{bots}{ substr( $file, 0, -5 ) } = $data;
        };
    }
    closedir($dh);
}

sub on_leave_state {
    my ( $self, $game ) = @_;

    for my $p ( values %{ $game->{players} } ) {
        $p->{public}{damage} = 0;
        $p->{public}{locked} = [];
    }
}

on 'join'         => "Gamed::State::WaitingForPlayers";
on 'list_players' => "Gamed::State::WaitingForPlayers";
on 'quit'         => "Gamed::State::WaitingForPlayers";

on 'bot' => sub {
    my ( $self, $player, $msg, $player_data ) = @_;
    my $game = $self->{game};

    if ( defined $player_data->{public}{bot} ) {
        $player->err("You already chose a bot");
        return;
    }

    if (   $msg->{bot}
        && exists $game->{public}{bots}{ $msg->{bot} }
        && !defined $game->{public}{bots}{ $msg->{bot} }{player} )
    {
        $game->{public}{bots}{ $msg->{bot} }{player} = $player->{in_game_id};
        $player_data->{public}{bot} = $msg->{bot};
        $self->{game}->broadcast( bot => { bot => $msg->{bot}, player => $player->{in_game_id} } );
    }
    else {
        $player->err("Invalid bot");
    }
};

on 'ready' => sub {
    my ( $self, $client, $msg, $player_data ) = @_;
    my $game = $self->{game};

    if ( !defined $player_data->{public}{bot} ) {
        $client->err("No bot chosen");
        return;
    }

    if ( keys %{ $game->{players} } >= $self->{min} ) {
        $player_data->{public}{ready} = 1;
        $game->broadcast( ready => { player => $client->{in_game_id} } );
        $game->change_state('PROGRAMMING')
          unless grep { !$_->{public}{ready} } values %{ $game->{players} };
    }
    else {
        $client->err("Not enough players");
    }
};

on 'not ready' => sub {
    my ( $self, $player, $msg ) = @_;
    my $game = $self->{game};
    $game->{players}{ $player->{in_game_id} }{public}{ready} = 0;
    $game->broadcast( 'not ready' => { player => $player->{in_game_id} } );
};

1;
