package Gamed;

use EV;
use AnyEvent;
use File::Basename 'dirname';
use File::Spec::Functions 'catdir';
use JSON::Any;
use File::Find;

my $json = JSON::Any->new;

our %games;
our %game_instances;
our %player;
our $VERSION = 0.1;
our %commands = { join => \&on_join, };

sub import {
    my ( $pgk, @path ) = @_;
    @path = ( 'Gamed', 'Game' ) unless @path;
    opendir DIR, catdir( dirname(__FILE__), @path );
    for my $file ( readdir DIR ) {
        my ($module) = $file =~ /(.*)\.pm/;
        next unless $module;
        eval "CORE::require Gamed::Game::$module";
        $games{$module} = bless [], "Gamed::Game::$module";
    }
    closedir(DIR);
}

sub on_connect {
    my ( $name, $sock ) = @_;
    $player{$name} = $sock;
    $sock->send( $json->to_json( { type => 'gamed', version => $VERSION, games => [ keys(%games) ] } ) );
}

sub on_message {
    my ( $name, $msg ) = @_;
    my $sock = $player{$name};
    if ( $msg->{type} eq 'game' ) {
    }
    elsif ( $msg->{type} eq 'chat' ) {
        $sock->send(
            $json->to_json(
                {
                    type => 'chat',
                    text => $msg->{'text'},
                    user => $name,
                }
            )
        );
    }
    elsif ( $msg->{type} eq 'main' ) {
        my $action = $msg->{action};
        my $cmd    = $commands{$action};
        if ( ref($cmd) eq 'CODE' ) {
            $cmd->($sock, $msg);
        }
        else {
            $sock->send( $json->to_json( { type => 'main', action => 'error', reason => "Unknown action '$action'" } ) );
        }
    }
}

sub on_disconnect {
    my $name = shift;
    delete $player{$name};
}

sub on_join {
	my ($sock, $msg) = @_;

}

1;
