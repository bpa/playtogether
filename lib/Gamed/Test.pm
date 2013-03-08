use Gamed qw/Gamed Test Game/;

package Gamed::Test;
use Exporter 'import';
our @EXPORT = qw/json text/;

my $j = JSON::Any->new;
sub json ($) { $j->to_json( $_[0] ) }
sub hash ($) { $j->from_json( $_[0] ) }

package SocketMock;

use Test::Builder;
use Data::Dumper;
$Data::Dumper::Terse = 1;

sub new {
    bless {}, shift;
}

sub send {
    my ( $self, $msg ) = @_;
    my $obj = $j->from_json($msg);
    push @{ $self->{packets} }, $obj;
}

sub got_one {
    my ( $self, $hash, $desc ) = @_;
    $hash ||= {};
    $desc ||= 'gotOne';
    my $tb = Test::Builder->new;

    if ( @{ $self->{packets} } == 1 ) {
        local $msg = shift @{ $self->{packets} };
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
        $tb->is_eq( scalar @{ $self->{packets} }, 1, "Received one message" );
    }
}

1;
