use 5.010;
use Mojolicious::Lite;
use Mojolicious::Sessions;
use Mojo::Server::Daemon;
use EV;
use AnyEvent;
use Mojo::IOLoop;
use File::Basename 'dirname';
use File::Spec::Functions 'catdir';
use Gamed::Server;
use JSON::Any;

my $sessions = Mojolicious::Sessions->new;
$sessions->cookie_name('gamed');
$sessions->default_expiration(86400);
my $json = JSON::Any->new;

get '/' => sub {
    my $self = shift;
    my $user = $self->session('user');
    my $game = $self->session('game');
    $self->app->log->debug("User: $user");
    $self->render(
        defined $user ? 'index' : 'login',
        user => $user,
        game => $game
    );
};

post '/login' => sub {
    my $self = shift;
    my $user = $self->param('username');
    if ( defined $user ) {
        $self->session( user => $user );
        $self->session( game => 'lobby' );
        $self->render( 'index', user => $user, game => 'lobby' );
    }
    else {
        $self->render('login');
    }
};

get '/lobby' => sub {
    my $self = shift;
    $self->render('lobby');
};

websocket '/websocket' => sub {
    my $self = shift;
    $self->app->log->debug('WebSocket connected.');
    Mojo::IOLoop->stream( $self->tx->connection )->timeout(3600);

    $self->on(
        message => sub {
            my ( $self, $msg ) = @_;
            my $obj = $json->jsonToObj($msg);

            given ( $obj->{'type'} ) {
                when ('chat') {
                    $self->send(
                        $json->objToJson({
                                type => 'chat',
                                text => $obj->{'text'},
                                user => $self->session('user')
                    }))
                }
            }
        }
    );

    $self->on(
        finish => sub {
            my $self = shift;
            $self->app->log->debug('WebSocket disconnected.');
        }
    );
};

my $daemon = Mojo::Server::Daemon->new( app => app, listen => ['http://*:8080'] );
$daemon->app->home->parse( catdir( dirname(__FILE__) . '/Gamed' ), 'Gamed' );
$daemon->app->static->paths->[0]   = $daemon->app->home->rel_dir('public');
$daemon->app->renderer->paths->[0] = $daemon->app->home->rel_dir('templates');
$daemon->start;

AE::cv->recv;
