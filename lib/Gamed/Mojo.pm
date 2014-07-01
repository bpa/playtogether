#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;

use Mojolicious::Lite;
use Mojo::Server::Daemon;
use EV;
use AnyEvent;
use AnyEvent::Handle;
use AnyEvent::Socket;
use Mojo::IOLoop;
use File::Basename 'dirname';
use File::Spec::Functions 'catdir';
use FindBin;
use Gamed;
use Gamed::Login;
use Gamed::Player;
use File::Slurp;

get '/' => sub {
    shift->render_static('index.html');
};

websocket '/websocket' => sub {
    my $self = shift;
    my $player;
    $self->app->log->debug('WebSocket connected.');
    Mojo::IOLoop->stream( $self->tx->connection )->timeout(3600);
    $player = Gamed::Player->new( { sock => $self } );
    $self->send('{"cmd":"login"}');
    $self->on(
        message => sub {
            my ( $self, $msg ) = @_;
            eval { $player->handle($msg); };
            $player->err($@) if $@;
        }
    );

    $self->on(
        finish => sub {
            on_disconnect( $self, $player );
            $self->app->log->debug('WebSocket disconnected.');
        }
    );
};

my %socket;
tcp_server 0, 3001, sub {
    my $fh = shift;
    my $player = Gamed::Player->new( { sock => TCP->new($fh) } );
    syswrite $fh, '{"cmd":"login"}';
    my $handle = AnyEvent::Handle->new(
        fh      => $fh,
        poll    => 'r',
        on_read => sub {
            my $self = shift;
            eval { $player->handle( $self->{rbuf} ) };
            $player->err($@) if $@;
			$self->{rbuf} = '';
			return 1;
        },
        on_error => sub { on_disconnect( shift, $player ) },
        on_eof   => sub { on_disconnect( shift, $player ) },
    );
    $socket{$handle} = $handle;
};

sub on_disconnect {
    my ( $self, $player ) = @_;
    $self->destroy() if $self->can('destroy');
    delete $player->{sock};
	delete $socket{$self};
   	$player->{game}->handle($player, { cmd => 'disconnected' } );
}

$Gamed::Login::secret = read_file( catdir( dirname(__FILE__), '.secret' ) );

#app->secrets( [ $gamed::Login::secret ] );
my $daemon = Mojo::Server::Daemon->new( app => app, listen => ['http://*:3000'] );
$daemon->app->home->parse( dirname(__FILE__), 'Gamed' );
$daemon->app->static->paths->[0]   = $daemon->app->home->rel_dir('public');
$daemon->app->renderer->paths->[0] = $daemon->app->home->rel_dir('public');
$daemon->run;

AE::cv->recv;

package TCP;

sub new {
    my ( $pkg, $fh ) = @_;
    bless { fh => $fh }, $pkg;
}

sub send {
    my ( $self, $msg ) = @_;
    syswrite $self->{fh}, $msg;
}

1;
