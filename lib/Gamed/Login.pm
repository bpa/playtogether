package Gamed::Login;

use Gamed::Handler;
use Gamed::Lobby;

use Gamed::DB;
use Data::UUID;

our %players;
my $uuid = Data::UUID->new;

sub new { bless {}, shift; }

on 'create_user' => sub {
    my ( $game, $player, $msg ) = @_;
    login( $player, Gamed::DB::create_user($msg) );
};

on 'login' => sub {
    my ( $game, $player, $msg ) = @_;
    if ( defined $msg->{token} ) {
        my $p = $players{ $msg->{token} };
        if ( defined $p ) {
            while ( my ( $k, $v ) = each(%$p) ) {
                $player->{$k} = $v;
            }
            $players{ $msg->{token} } = $player;
            $player->send( welcome => { token => $player->{id} } );
            if ( ref( $player->{game} ) ne 'Gamed::Lobby' ) {
                $player->send( join => { game => $player->{game}{game} } );
            }
        }
        else {
            $player->err("Can't reconnect");
        }
    }
    else {
        login( $player, Gamed::DB::login($msg) );
    }
};

sub login {
    my ( $player, $user ) = @_;
    if ($user) {
        $player->{user}           = $user;
        $player->{id}             = $uuid->create_str();
        $player->{game}           = Gamed::Lobby->new();
        $players{ $player->{id} } = $player;
        $player->send( welcome => { token => $player->{id} } );
    }
    else {
        $player->err("Login failed");
    }
}

