package Gamed;

use strict;
use warnings;

use EV;
use AnyEvent;
use File::Basename 'dirname';
use File::Spec::Functions 'catdir';
use Gamed::Game;
use Gamed::Player;
use JSON::Any;
use File::Find;
use Data::UUID;

my $json = JSON::Any->new;
my $uuid = Data::UUID->new;

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
    my ( $pgk, @path ) = @_;
    @path = ( 'Gamed', 'Game' ) unless @path;
    opendir DIR, catdir( dirname(__FILE__), @path );
    for my $file ( readdir DIR ) {
        my ($module) = $file =~ /(.*)\.pm$/;
        next unless $module;
        my $pkg = join( '::', @path, $module );
        eval "CORE::require $pkg";
        $games{$module} = $pkg;
    }
    closedir(DIR);
}

sub json ($$) { $_[0]->send( $json->to_json( $_[1] ) ) }

sub err ($$) {
    $_[0]->send( $json->to_json( { cmd => "error", reason => $_[1] } ) );
}

sub on_connect {
    my ( $name, $sock ) = @_;
	my $id = $uuid->create_b64;
	my $player = Gamed::Player($name, $sock, $id);
    $connection{$id} = $player;
    json $sock,
      { cmd     => 'gamed',
        version => $VERSION,
        games   => [ keys(%games) ] };
	return $id;
}

sub on_message {
    my ( $name, $msg_json ) = @_;
    my $msg  = $json->from_json($msg_json);
    my $sock = $player{$name};
    my $cmd  = $msg->{cmd};
    if ( !defined($cmd) ) {
          err $sock, "No cmd specified";
    }
    elsif ( exists $commands{$cmd} ) {
        $commands{$cmd}( $name, $sock, $msg );
    }
    else {
          err $sock, "Unknown cmd '$cmd'";
    }
}

sub on_chat {
    my ( $name, $sock, $msg ) = @_;
    json $sock, { cmd => 'chat', text => $msg->{'text'}, user => $name };
}

sub on_create {
    my ( $name, $sock, $msg ) = @_;
    if ( exists $game_instances{ $msg->{name} } ) {
          err $sock, "A game named '" . $msg->{name} . "' already exists";
        return;
    }
    if ( exists $games{ $msg->{game} } ) {
        eval {
            my $game = Gamed::Game::create( $games{ $msg->{game} } );
            $game_instances{ $msg->{name} } = $game;
            $game->on_join( $name, $sock );
            $msg->{cmd} = 'join';
            json $sock, $msg;
        };
        if ($@) {
            $game_instances{ $msg->{name} }->on_destroy
              if exists $game_instances{ $msg->{name} };
            delete $game_instances{ $msg->{name} };
              err $sock, $@;
        }
    }
}

sub on_join {
    my ( $name, $sock, $msg ) = @_;
    my $game = $msg->{'game'};
    if ( !defined( $game_instances{$game} ) ) {
          err $sock, "No game named '$game' exists";
    }
    else {
        eval {
            my $instance = $game_instances{$game};
            $instance->on_join( $name, $sock );
            json $sock, $msg;
        };
        if ($@) {
              err $sock, $@;
        }
    }
}

sub on_game {
    my ( $name, $sock, $msg ) = @_;
	my $game = 
}

sub on_disconnect {
    my $name = shift;
    delete $player{$name};
}

1;
