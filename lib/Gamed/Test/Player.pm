package Gamed::Test::Player;

use JSON::MaybeXS;
use Data::UUID;
use Data::Dumper;
use Test::Builder;
use Test::Deep::NoTest;
use Hash::Merge 'merge';
use parent 'Gamed::Player';

my $json = JSON::MaybeXS->new(convert_blessed => 1);
my $tb   = Test::Builder->new;
my $uuid = Data::UUID->new;

sub new {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $pkg, $name ) = @_;
    $name ||= 'test';
    my $self = bless Gamed::Player->new( { sock => SocketMock->new } ), $pkg;
    $self->handle( { cmd => 'login', name => $name } );
    $self->{sock}->got( { cmd => 'welcome', token => ignore(), username => ignore() } );
    return $self;
}

sub handle {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $self, $msg ) = @_;
    eval { Gamed::Player::handle( $self, $json->encode($msg) ); };
    print Dumper $@ if $@;
    $self->err($@) if $@;
}

sub create {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $self, $game, $name, $opts, $more ) = @_;
    $opts ||= {};
    $opts->{cmd}  = 'create';
    $opts->{game} = $game;
    $opts->{name} = $name;
    $self->handle($opts);
	for my $p (values %Gamed::Login::players) {
		$p->{sock}{packets} = [];
	}
    return $self->join($name, $more);
}

sub join {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $self, $name, $opts ) = @_;
    $opts ||= {};
    $self->handle( { cmd => 'join', name => $name } );
    my $expected = { 
            cmd    => 'join',
            player => {
                id       => $self->{in_game_id},
                name     => ignore(),
                avatar   => ignore(),
                username => ignore(),
            },
            name => ignore(),
            game => ignore(),
        };
    Gamed::Test::broadcast( $self->{game}, merge($expected, $opts), "Got join" );
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
    $msg = { $cmd => $msg } if $msg && !ref($msg);
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

sub reset {
	my $self = shift;
	$self->{sock}{packets} = [];
}

1;
