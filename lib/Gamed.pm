package Gamed;

use strict;
use warnings;

use EV;
use AnyEvent;
use File::Basename 'dirname';
use File::Spec::Functions 'catdir';
use Gamed::Const;
use Gamed::Game;
use Gamed::Player;
use File::Find;
use Data::UUID;
use JSON::Any;

my $uuid = Data::UUID->new;
my $json = JSON::Any->new;

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

sub err ($$) {
	chomp($_[1]);
    $_[0]->send( { cmd => "error", reason => $_[1] } );
}

sub on_connect {
    my ( $name, $sock ) = @_;
	my $id = $uuid->create_b64;
	my $player = Gamed::Player->new({ name=>$name, sock=>$sock, id=>$id});
    $connection{$id} = $player;
    $player->send(
      { cmd     => 'gamed',
        version => $VERSION,
        games   => [ keys(%games) ] });
	return $id;
}

sub on_message {
    my ( $id, $msg_json ) = @_;
    my $msg  = $json->from_json($msg_json);
    my $player = $connection{$id};
	return unless defined $player;
    my $cmd  = $msg->{cmd};
    if ( !defined($cmd) ) {
          err $player, "No cmd specified";
    }
    elsif ( exists $commands{$cmd} ) {
        $commands{$cmd}( $player, $msg );
    }
    else {
          err $player, "Unknown cmd '$cmd'";
    }
}

sub on_chat {
    my ( $player, $msg ) = @_;
    $player->send({ cmd => 'chat', text => $msg->{'text'}, user => $player->{name} });
}

sub on_create {
    my ( $player, $msg ) = @_;
    if ( exists $game_instances{ $msg->{name} } ) {
          err $player, "A game named '" . $msg->{name} . "' already exists";
        return;
    }
    if ( exists $games{ $msg->{game} } ) {
        eval {
            my $game = Gamed::Game::create( $games{ $msg->{game} } );
            $game_instances{ $msg->{name} } = $game;
            my $r = $game->on_join( $player );
			$player->{game} = $game;
            $msg->{cmd} = 'join';
            $player->send($msg);
        };
        if ($@) {
            $game_instances{ $msg->{name} }->on_destroy
              if exists $game_instances{ $msg->{name} };
            delete $game_instances{ $msg->{name} };
              err $player, $@;
        }
    }
	else {
		err $player, "No game type '".$msg->{game}."' exists";
	}
}

sub on_join {
    my ( $player, $msg ) = @_;
    my $name = $msg->{'name'};
    if ( !defined( $game_instances{$name} ) ) {
          err $player, "No game named '$name' exists";
    }
    else {
        eval {
            my $instance = $game_instances{$name};
            $instance->on_join( $player );
			$player->{game} = $instance;
            $player->send($msg);
        };
        if ($@) {
              err $player, $@;
        }
    }
}

sub on_game {
    my ( $player, $msg ) = @_;
	my $game = $player->{game};
	$game->on_message($player, $msg);
}

sub on_disconnect {
	my $id = shift;
    delete $connection{$id};
}

1;
