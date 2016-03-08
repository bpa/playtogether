package SocketMock;

use Test::More;
use Test::Builder;
use Test::Deep::NoTest qw/cmp_details deep_diag/;
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
        $tb->is_eq( scalar @{ $self->{packets} }, 1, "$desc Received too many responses" );
        #print STDERR Dumper $self->{packets} if @{ $self->{packets} };
    }
}

sub got {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $self, $hash, $desc ) = @_;
    my $msg  = shift @{ $self->{packets} };
    my ($ok, $stack) = cmp_details($msg, $hash);
    unless($tb->ok($ok, $desc)) {
        my $diag = deep_diag($stack);
        $tb->diag($diag);
    }
}

1;
