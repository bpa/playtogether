package Gamed::Test::Connection;

use Test::Builder;
my $tb = Test::Builder->new;

sub new {
    my ( $pkg, $name ) = @_;
    $name ||= 'test';
    my $self = bless { sock => SocketMock->new }, shift;
    $self->{id} = Gamed::on_connect( $name, $self->{sock} );
    $self->{sock}->got_one( {}, "$name connected" );
    return $self;
}

sub create {
    my ( $self, $game, $name, $opts ) = @_;
    Gamed::on_create( $self, { cmd => 'create', game => $game, name => $name, opts => $opts } );
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $self->{sock}->got_one( { cmd => 'join', name => $name }, 'create' );
}

sub join {
    my ( $self, $name ) = @_;
    Gamed::on_join( $self, { cmd => 'join', name => $name } );
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $self->{sock}->got( { cmd => 'join', name => $name }, 'join' );
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
	my ($self, $reason) = @_;
	$self->{sock}->send({ cmd => 'error', reason => $reason});
}

1;
