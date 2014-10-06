package Gamed::Game::RoboRally;

use File::Basename;
use File::Spec::Functions 'catdir';
use Gamed::Handler;
use Gamed::Game::RoboRally::Setup;
use Gamed::Game::RoboRally::Programming;
use Gamed::Game::RoboRally::Executing;

use Gamed::Handler;
use parent 'Gamed::Game';

use Gamed::States {
    WAITING_FOR_PLAYERS => Gamed::State::WaitingForPlayers->new( next     => 'SETUP' ),
    SETUP               => Gamed::Game::RoboRally::Setup->new( next       => 'PROGRAMMING' ),
    PROGRAMMING         => Gamed::Game::RoboRally::Programming->new( next => 'EXECUTING' ),
    EXECUTING           => Gamed::Game::RoboRally::Executing->new,
    GAME_OVER           => Gamed::State::GameOver->new,
};

on 'create' => sub {
    my ( $self, $player, $msg ) = @_;
    $msg->{course} ||= 'Checkmate';
    $self->{public}{course} = Gamed::Game::RoboRally::Course->new( $msg->{course} );
    $self->{min_players}    = 2;
    $self->{max_players}    = 8;

    opendir( my $dh, catdir( $Gamed::public, "g", "RoboRally", "bots" ) );
    for my $file ( grep { !/^\./ && /\.json$/ } readdir($dh) ) {
        $self->{public}{bots}{ substr( $file, 0, -5 ) } = ();
    }
    closedir($dh);

    $self->change_state('WAITING_FOR_PLAYERS');
};

on 'join' => sub {
    my ( $self, $player, $msg ) = @_;
    my $bot = ( keys %{ $self->{public}{bots} } )[ rand keys %{ $self->{public}{bots} } ];
    $self->{public}{bots}{$bot} = $player->{in_game_id};
    $self->{players}{ $player->{in_game_id} }{public}{bot} = $bot;
};

on 'bot' => sub {
    my ( $self, $player, $msg ) = @_;
    if (   $msg->{bot}
        && exists $self->{public}{bots}{ $msg->{bot} }
        && !defined $self->{public}{bots}{ $msg->{bot} } )
    {
        $self->{public}{bots}{ $self->{players}{ $player->{in_game_id} }{public}{bot} } = ();
        $self->{public}{bots}{ $msg->{bot} }                                            = $player->{in_game_id};
        $self->{players}{ $player->{in_game_id} }{public}{bot}                          = $msg->{bot};
        $self->broadcast( bot => { bot => $msg->{bot}, player => $player->{in_game_id} } );
    }
    else {
        $player->err("Invalid bot");
    }
};

on 'quit' => sub {
    my ( $self, $client, $msg, $player ) = @_;
    $self->{public}{bots}{ delete $player->{public}{bot} } = ();
};

1;
