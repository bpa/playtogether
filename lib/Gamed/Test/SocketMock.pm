package SocketMock;

use Test::More;
use Test::Builder;
use Data::Dumper;
my $tb = Test::Builder->new;
$Data::Dumper::Terse = 1;
use JSON::MaybeXS;

my $json = JSON::MaybeXS->new(convert_blessed => 1);

sub new {
    bless {}, shift;
}

sub send {
    my ( $self, $msg ) = @_;
    push @{ $self->{packets} }, $json->decode($json->encode($msg));
}

sub got_one {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $self, $hash, $desc ) = @_;
    $hash ||= {};
    $desc ||= 'gotOne';

    if ( @{ $self->{packets} } == 1 ) {
        $self->got( $hash, $desc );
    }
    else {
        $tb->is_eq( scalar @{ $self->{packets} }, 1, "$desc Received response" );
        print STDERR Dumper $self->{packets} if @{ $self->{packets} };
    }
}

sub got {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
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
        elsif ( ref($v) eq 'ARRAY' ) {
			my ($exp) = $tb->explain($msg->{$k});
			my ($want) = $tb->explain($v);
			if ( $exp ne $want ) {
				$pass = 0;
				last;
			}
        }
        else {
            if ( !exists($msg->{$k}) || ($msg->{$k} && $msg->{$k} ne $v) ) {
                $pass = 0;
                last;
            }
        }
    }
    $pass ? $tb->ok( 1, $desc ) : $tb->is_eq( $tb->explain($msg), $tb->explain($hash), $desc );
    $pass ? $tb->ok( 1, $desc ) : is_deeply( $msg, $hash, $desc );
}

1;
