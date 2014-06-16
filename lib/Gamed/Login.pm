package Gamed::Login;

use Gamed::Handler;
use Gamed::Lobby;

use Gamed::DB;
use Data::UUID;

our %players;
our $secret;
my $uuid = Data::UUID->new;

sub new { bless {}, shift; }

on 'create_user' => sub {
    my ( $game, $player, $msg ) = @_;
    login( $player, Gamed::DB::create_user($msg) );
};

on 'login' => sub {
    my ( $game, $player, $msg ) = @_;
    if ( my $username = signed_value( $msg->{username} ) ) {
        my $p = defined $msg->{token} ? $players{ $msg->{token} } : undef;
        if ( $p && ref( $p->{game} ) ne 'Gamed::Lobby' ) {
            while ( my ( $k, $v ) = each(%$p) ) {
                $player->{$k} = $v;
            }
            $players{ $msg->{token} } = $player;
            $player->{game}{players}{ $player->{in_game_id} }{client} = $player;
            $player->send( join => { game => $player->{game}{game}, name => $player->{game}{name}, player => $player->{in_game_id} } );
        }
        else {
            login( $player, Gamed::DB::get_user($username) );
        }
    }
    else {
        login( $player, Gamed::DB::login($msg) );
    }
};

sub signed_value {
    my $msg = shift;
    return unless $msg;
    my ( $value, $signature ) = $msg =~ /^(.*)--([^-]+)$/;
    return unless $signature;
    my $check = Mojo::Util::hmac_sha1_sum( $value, $secret );
    if ( Mojo::Util::secure_compare( $signature, $check ) ) {
        return $value;
    }
    return;
}

sub login {
    my ( $player, $user ) = @_;
    if ($user) {
        $player->{id}             = $uuid->create_str();
        $player->{user}           = $user;
        $player->{game}           = Gamed::Lobby->new();
        $players{ $player->{id} } = $player;
        $player->send(
            welcome => {
                token    => $player->{id},
                username => $user->{username} . "--" . Mojo::Util::hmac_sha1_sum( $user->{username}, $secret ) } );
    }
    else {
        $player->err("Login failed");
    }
}

1;
