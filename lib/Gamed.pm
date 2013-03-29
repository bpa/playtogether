package Gamed;

use strict;
use warnings;

use AnyEvent;
use Data::UUID;
use EV;
use Gamed::Const;
use Gamed::Game;
use Gamed::Player;
use JSON;
use Module::Pluggable::Object;

my $uuid = Data::UUID->new;
my $json = JSON->new->convert_blessed;

our %games;
our %game_instances;
our %connection;
our $VERSION = 0.1;
my %commands = (
    join   => \&on_join,
    chat   => \&on_chat,
    game   => \&on_game,
    create => \&on_create
);

sub import {
    my ( $pgk, $path ) = ( @_, "Gamed::Game" );
    my $finder = Module::Pluggable::Object->new( search_path => $path, require => 1, inner => 0 );
	for my $game ($finder->plugins) {
		if (my ($shortname) = $game =~ /::Game::([^:]+)$/) {
			$games{$shortname} = $game;
		}
	}
}

sub on_connect {
    my ( $name, $sock ) = @_;
    my $id = $uuid->create_b64;
    my $player = Gamed::Player->new( { name => $name, sock => $sock, id => $id } );
    $connection{$id} = $player;
    $player->send(
        {   cmd     => 'gamed',
            version => $VERSION,
            games   => [ keys(%games) ] } );
    return $id;
}

sub on_message {
    my ( $id, $msg_json ) = @_;
    my $msg    = $json->decode($msg_json);
    my $player = $connection{$id};
    return unless defined $player;
    my $cmd = $msg->{cmd};
    if ( !defined($cmd) ) {
          $player->err("No cmd specified");
    }
    elsif ( exists $commands{$cmd} ) {
        $commands{$cmd}( $player, $msg );
    }
    else {
          $player->("Unknown cmd '$cmd'");
    }
}

sub on_chat {
    my ( $player, $msg ) = @_;
    $player->send( { cmd => 'chat', text => $msg->{'text'}, user => $player->{name} } );
}

sub on_create {
    my ( $player, $msg ) = @_;
    if ( exists $game_instances{ $msg->{name} } ) {
          $player->err( "A game named '" . $msg->{name} . "' already exists" );
        return;
    }
    if ( exists $games{ $msg->{game} } ) {
        eval {
            my $game = Gamed::Game::new( $games{ $msg->{game} }, $msg );
            $game_instances{ $msg->{name} } = $game;
            $msg->{cmd}     = 'join';
            my $r = $game->on_join($player, $msg);
            $player->{game} = $game;
        };
        if ($@) {
            $game_instances{ $msg->{name} }->on_destroy
              if exists $game_instances{ $msg->{name} };
            delete $game_instances{ $msg->{name} };
              $player->err($@);
        }
    }
    else {
          $player->err( "No game type '" . $msg->{game} . "' exists" );
    }
}

sub on_join {
    my ( $player, $msg ) = @_;
    my $name = $msg->{'name'};
    if ( !defined( $game_instances{$name} ) ) {
          $player->err( "No game named '$name' exists" );
    }
    else {
        eval {
            my $instance = $game_instances{$name};
            $instance->on_join($player, $msg);
            $player->{game} = $instance;
        };
        if ($@) {
              $player->err( $@ );
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
          $player->err( $@ );
    }
}

sub on_disconnect {
    my $id = shift;
    delete $connection{$id};
}

1;
