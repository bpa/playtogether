package Gamed::Test::Player;

use JSON;
use Data::UUID;
use Test::Builder;
use parent 'Gamed::Player';

my $json = JSON->new->convert_blessed;
my $tb   = Test::Builder->new;
my $uuid = Data::UUID->new;

sub new {
    my ( $pkg, $name ) = @_;
    $name ||= 'test';
    my $self = bless Gamed::Player->new( { sock => SocketMock->new } ), $pkg;
    $self->handle( { cmd => 'login', name => $name } );
    $self->{sock}->got( { cmd => 'welcome' } );
    return $self;
}

sub handle {
    my ( $self, $msg ) = @_;
    eval { Gamed::Player::handle( $self, $json->encode($msg) ); };
    $self->err($@) if $@;
}

sub create {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $self, $game, $name, $opts ) = @_;
    $opts ||= {};
    $opts->{cmd}  = 'create';
    $opts->{game} = $game;
    $opts->{name} = $name;
    $self->handle($opts);
	for my $p (values %Gamed::Login::players) {
		$p->{sock}{packets} = [];
	}
    return $self->join($name);
}

sub join {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $self, $name ) = @_;
    $self->handle( { cmd => 'join', name => $name } );
    Gamed::Test::broadcast(
        $self->{game},
        {
            cmd     => 'join',
            player  => sub { $_[0]->{id} eq $self->{in_game_id} },
        },
        "Got join"
    );
    return $self->{game};
}

sub quit {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $self = shift;
	my $game = $self->{game};
    $self->handle( { cmd => 'quit' } );
    Gamed::Test::broadcast( $game, { cmd => 'quit', player => $self->{in_game_id} }, 'Quit broadcast' );
}

sub game {
    my ( $self, $msg, $test, $desc ) = @_;
    $self->handle($msg);
    if ( defined $test ) {
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        $self->{sock}->got_one( $test, $desc );
    }
}

sub broadcast {
    my ( $self, $msg, $test, $desc ) = @_;
    $test ||= $msg;
    $self->handle($msg);
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    Gamed::Test::broadcast_one( $self->{game}, $test, $desc );
}

sub got {
    my $self = shift;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $self->{sock}->got(@_);
}

sub got_one {
    my $self = shift;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $self->{sock}->got_one(@_);
}

sub send {
    my ( $self, $cmd, $msg ) = @_;
    $msg->{cmd} = $cmd;
	#print (($self->{user} ? $self->{user}{name} : '?'), " got ", $json->encode($msg), "\n");
    $self->{sock}->send($msg);
}

sub err {
    my ( $self, $reason ) = @_;
    chomp($reason);
	#print (($self->{user} ? $self->{user}{name} : '?'), " ERR: $reason\n");
    $self->{sock}->send( { cmd => 'error', reason => $reason } );
}

1;
