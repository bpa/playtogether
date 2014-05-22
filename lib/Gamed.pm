package Gamed;

use strict;
use warnings;

use AnyEvent;
use EV;
use File::Basename 'dirname';
use File::Spec::Functions 'catdir';
use Gamed::Const;
use Gamed::Game;
use Gamed::Player;
use JSON;
use Module::Pluggable::Object;
use FindBin;
use Data::UUID;
use Gamed::DB;

our $public = catdir( dirname(__FILE__), 'Gamed', 'public' );
my $json = JSON->new->convert_blessed;
my $uuid = Data::UUID->new;

our %games;
our %players;
our %game_instances;
our $VERSION = 0.1;
our %cmd     = (
    login       => \&on_login,
    create_user => \&on_create_user,
    join        => \&on_join,
    create      => \&on_create,
    quit        => \&on_quit,
);

sub import {
    my ( $pgk, $path ) = ( @_, "Gamed::Game" );
    my $finder = Module::Pluggable::Object->new(
        search_path => $path,
        require     => 1,
        inner       => 0
    );
    for my $game ( $finder->plugins ) {
        if ( my ($shortname) = $game =~ /::Game::([^:]+)$/ ) {
            $games{$shortname} = $game;
        }
    }
}

sub on_message {
    my ( $player, $msg_json ) = @_;
    my $msg = $json->decode($msg_json);
    my $cmd = $msg->{cmd};
    if ( !defined $player->{id} ) {
        $cmd = 'login';
    }
    my $action = $cmd{$cmd};
    if ( defined $player->{game} && !defined $action ) {
        on_game( $player, $msg );
    }
    elsif ( defined $action ) {
        $action->( $player, $msg );
    }
    else {
        die "Command '" + $cmd + "' not valid\n";
    }
}

sub on_create_user {
    my ( $player, $msg ) = @_;
    login( $player, Gamed::DB::create_user($msg) );
}

sub on_login {
    my ( $player, $msg ) = @_;
    if ( defined $msg->{cmd} && $msg->{cmd} eq 'reconnect' ) {
        my $p = $players{ $msg->{id} };
        if ( defined $p ) {
            while ( my ( $k, $v ) = each(%$p) ) {
                $player->{$k} = $v;
            }
            $players{ $msg->{id} } = $player;
            my @inst;
            while ( my ( $k, $v ) = each %game_instances ) {
                push @inst,
                  { name    => $k,
                    game    => $v->{game},
                    players => [ map { $_->{name} } $v->{players} ],
                    status  => $v->{status} };
            }
            $player->send( { cmd => 'games', games => [ sort keys %games ], instances => \@inst } );
        }
        else {
            $player->err("Can't reconnect");
        }
    }
    else {
        login( $player, Gamed::DB::login($msg) );
    }
}

sub login {
    my ( $player, $user ) = @_;
    if ($user) {
        $player->{user}           = $user;
        $player->{id}             = $uuid->create_str();
        $players{ $player->{id} } = $player;
        my @inst;
        while ( my ( $k, $v ) = each %game_instances ) {
            push @inst,
              { name    => $k,
                game    => $v->{game},
                players => [ map { $_->{name} } $v->{players} ],
                status  => $v->{status} };
        }
        $player->send( { cmd => 'games', games => [ sort keys %games ], instances => \@inst } );
    }
    else {
        $player->err("Login failed");
    }
}

sub on_create {
    my $msg = shift;
    if ( exists $game_instances{ $msg->{name} } ) {
        die "A game named '" . $msg->{name} . "' already exists.\n";
        return;
    }
    if ( exists $games{ $msg->{game} } ) {
        eval {
            my $game = $games{ $msg->{game} }->create($msg);
            $game->{name} = $msg->{name};
            $game_instances{ $msg->{name} } = $game;
            for my $p ( values %players ) {
                $p->send( { cmd => 'create', name => $msg->{name}, game => $msg->{game} } )
                  if defined $p->{sock} && !defined $p->{game};
            }
        };
        if ($@) {
            $game_instances{ $msg->{name} }->on_destroy
              if exists $game_instances{ $msg->{name} };
            delete $game_instances{ $msg->{name} };
            die $@;
        }
    }
    else {
        die "No game type '" . $msg->{game} . "' exists\n";
    }
}

sub on_join {
    my ( $player, $name ) = @_;
    if ( !defined( $game_instances{$name} ) ) {
        $player->err("No game named '$name' exists");
    }
    else {
        eval {
            #on_quit($player) if defined $player->{game};
            my $instance = $game_instances{$name};
            $instance->on_join($player);
            $player->{game} = $instance;
        };
        if ($@) {
            $player->err($@);
        }
    }
}

sub on_game {
    my ( $player, $msg ) = @_;
    eval {
        my $game = $player->{game};
        $game->on_message( $player, $msg );
    };
    if ($@) {
        $player->err($@);
    }
}

sub on_quit {
    my $player = shift;
    my $game   = $player->{game};
    eval { $game->on_quit($player); };
    eval {
        if ( !keys %{ $game->{players} } ) {
            delete $game_instances{ $game->{name} };
            $game->on_destroy();
        }
    };
}

1;
