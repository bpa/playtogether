package Gamed::Test::Player;

use Data::UUID;
use Test::Builder;
my $tb   = Test::Builder->new;
my $uuid = Data::UUID->new;

sub new {
    my ( $pkg, $name ) = @_;
    $name ||= 'test';
    bless { sock => SocketMock->new, id => $uuid->create_b64, name => $name }, shift;
}

sub create {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $self, $game, $name, $opts ) = @_;
    $opts ||= {};
    $opts->{game} = $game;
    $opts->{name} = $name;
    Gamed::on_create($opts);
    return $self->join($name);
}

sub join {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $self, $name ) = @_;
    Gamed::on_join( $self, $name );
    my %players;
    for my $p ( values %{ $self->{game}{players} } ) {
        $players{ $p->{in_game_id} } = $p->{public};
    }
    Gamed::Test::broadcast_one(
        $self->{game},
        {   cmd     => 'join',
            players => \%players,
            player  => $self->{in_game_id},
        }, "Got join" );
    return $self->{game};
}

sub quit {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $self = shift;
    Gamed::on_quit($self);
    Gamed::Test::broadcast_one( $self->{game},
        { cmd => 'quit', player => $self->{in_game_id} }, 'Quit broadcast' );
}

sub game {
    my ( $self, $msg, $test, $desc ) = @_;
    Gamed::on_game( $self, $msg );
    if ( defined $test ) {
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        $self->{sock}->got_one( $test, $desc );
    }
}

sub broadcast {
    my ( $self, $msg, $test, $desc ) = @_;
	$test ||= $msg;
    Gamed::on_game( $self, $msg );
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
    my $self = shift;
    $self->{sock}->send(@_);
}

sub err {
    my ( $self, $reason ) = @_;
    chomp($reason);
    $self->{sock}->send( { cmd => 'error', reason => $reason } );
}

1;
