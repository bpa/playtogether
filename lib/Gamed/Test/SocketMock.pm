package SocketMock;

use Test::Builder;
use Data::Dumper;
my $tb = Test::Builder->new;
$Data::Dumper::Terse = 1;

sub new {
    bless {}, shift;
}

sub send {
    my ( $self, $msg ) = @_;
    push @{ $self->{packets} }, $msg;
}

sub got_one {
    my ( $self, $hash, $desc ) = @_;
    $hash ||= {};
    $desc ||= 'gotOne';

    if ( @{ $self->{packets} } == 1 ) {
    	local $Test::Builder::Level = $Test::Builder::Level + 1;
		$self->got($hash, $desc);
    }
    else {
        $tb->is_eq( scalar @{ $self->{packets} }, 1, "$desc Received response" );
        print STDERR Dumper $self->{packets} if scalar( @{ $self->{packets} } );
    }
}

sub got {
    my ( $self, $hash, $desc ) = @_;
    my $msg  = shift @{ $self->{packets} };
    my $pass = 1;
    while ( my ( $k, $v ) = each(%$hash) ) {
        if ( ref($v) eq 'CODE' ) {
            if ( !$tb->ok( $v->( $msg->{$k} ), $k ) ) {
                $pass = 0;
                last;
            }
        }
        if ( ref($v) eq 'ARRAY' ) {
            if ( Dumper($v) ne Dumper($msg->{$k}) ) {
                $pass = 0;
                last;
            }
        }
        else {
            if ( !exists($msg->{$k}) || $msg->{$k} ne $v ) {
                $pass = 0;
                last;
            }
        }
    }
    $pass ? $tb->ok( 1, $desc ) : $tb->is_eq( Dumper($msg), Dumper($hash), $desc );
}

1;
