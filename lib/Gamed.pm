package Gamed;

use strict;
use warnings;

use AnyEvent;
use EV;
use Gamed::Const;
use Gamed::Game;
use Gamed::Player;
use JSON;
use Module::Pluggable::Object;
use FindBin;

our $resources = "$FindBin::Bin/../resources";

my $json = JSON->new->convert_blessed;

our %games;
our %game_instances;
our $VERSION = 0.1;

sub import {
    my ( $pgk, $path ) = ( @_, "Gamed::Game" );
    my $finder = Module::Pluggable::Object->new( search_path => $path, require => 1, inner => 0 );
    for my $game ( $finder->plugins ) {
        if ( my ($shortname) = $game =~ /::Game::([^:]+)$/ ) {
            $games{$shortname} = $game;
        }
    }
}

sub on_message {
    my ( $player, $msg_json ) = @_;
    my $msg = $json->decode($msg_json);
    $player->{game}->on_message( $player, $msg );
}

sub on_create {
    my $msg = shift;
    if ( exists $game_instances{ $msg->{name} } ) {
        die "A game named '" . $msg->{name} . "' already exists.\n";
        return;
    }
    if ( exists $games{ $msg->{game} } ) {
        eval {
            my $game = Gamed::Game::new( $games{ $msg->{game} }, $msg );
			$game->{name} = $msg->{name};
            $game_instances{ $msg->{name} } = $game;
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
            my $instance = $game_instances{$name};
            $instance->on_join( $player );
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
    my $game = $player->{game};
    eval {
        $game->on_quit($player);
    };
	eval {
		if (!keys %{ $game->{players} }) {
			delete $game_instances{$game->{name}};
			$game->on_destroy();
		}
	};
}

1;
