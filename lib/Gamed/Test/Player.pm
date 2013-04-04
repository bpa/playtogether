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

sub join {
    my ( $self, $name ) = @_;
    Gamed::on_join( $self, $name );
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $self->{sock}->got( { cmd => 'join'}, 'join' );
}

sub game {
    my ( $self, $msg, $test, $desc ) = @_;
    Gamed::on_game( $self, $msg );
    if ( defined $test ) {
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        $self->{sock}->got_one( $test, $desc );
    }
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
