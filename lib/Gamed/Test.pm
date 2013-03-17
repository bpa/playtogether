use Gamed 'Gamed::Test::Game';
use strict;
use warnings;

package Gamed::Test;
use Exporter 'import';
our @EXPORT = qw/json text client game broadcast_one/;

use Test::Builder;
my $tb = Test::Builder->new;

my $j = JSON->new->convert_blessed;
sub json ($) { $j->encode( $_[0] ) }
sub hash ($) { $j->decode( $_[0] ) }
sub client   { Gamed::Test::Connection->new(shift) }

sub game {
    my ( $game, $name, @players ) = @_;
    my @connections;
    my $created = 0;
    for (@players) {
        my $c = client($_);
        $created ? $c->join($name) : $c->create( $game, $name );
        $created = 1;
        push @connections, $c;
    }
    return @connections;
}

sub broadcast_one {
    my $game = shift;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    for my $p ( @{ $game->{players} } ) {
        $p->{sock}->got_one(@_);
    }
}

package SocketMock;

use Test::Builder;
use Data::Dumper;
$Data::Dumper::Terse = 1;

sub new {
    bless {}, shift;
}

sub send {
    my ( $self, $msg ) = @_;
    my $obj = $j->decode($msg);
    push @{ $self->{packets} }, $obj;
}

sub got_one {
    my ( $self, $hash, $desc ) = @_;
    $hash ||= {};
    $desc ||= 'gotOne';

    if ( @{ $self->{packets} } == 1 ) {
        my $msg  = shift @{ $self->{packets} };
        my $pass = 1;
        while ( my ( $k, $v ) = each(%$hash) ) {
            if ( ref($v) eq 'CODE' ) {
                if ( !$tb->ok( $v->( $msg->{$k} ), $k ) ) {
                    $pass = 0;
                    last;
                }
            }
            else {
                if ( $msg->{$k} ne $v ) {
                    $pass = 0;
                    last;
                }
            }
        }
        $pass ? $tb->ok( 1, $desc ) : $tb->is_eq( Dumper($msg), Dumper($hash), $desc );
    }
    else {
        $tb->is_eq( scalar @{ $self->{packets} }, 1, "$desc Received response" );
        print STDERR Dumper $self->{packets} if scalar( @{ $self->{packets} } );
    }
}

package Gamed::Test::Connection;

sub new {
    my ( $pkg, $name ) = @_;
    $name ||= 'test';
    my $self = bless { sock => SocketMock->new }, shift;
    $self->{id} = Gamed::on_connect( $name, $self->{sock} );
    $self->{sock}->got_one( {}, "$name connected" );
    return $self;
}

sub create {
    my ( $self, $game, $name ) = @_;
    Gamed::on_message( $self->{id}, $j->encode( { cmd => 'create', game => $game, name => $name } ) );
    $self->{sock}->got_one( { cmd => 'join', name => $name }, 'create' );
}

sub join {
    my ( $self, $name ) = @_;
    Gamed::on_message( $self->{id}, $j->encode( { cmd => 'join', name => $name } ) );
    $self->{sock}->got_one( { cmd => 'join', name => $name }, 'join' );
}

sub game {
    my ( $self, $msg, $test, $desc ) = @_;
    $msg->{cmd} = 'game';
    Gamed::on_message( $self->{id}, $j->encode($msg) );
    if ( defined $test ) {
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        $self->{sock}->got_one( $test, $desc );
    }
}

sub got_one {
    my $self = shift;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $self->{sock}->got_one(@_);
}

1;
