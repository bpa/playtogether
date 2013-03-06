use Gamed qw/Gamed Test Game/;

package SocketMock;

use JSON::Any;
use Test::Builder;
use Data::Dumper;

my $j = JSON::Any->new;

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

    $tb->subtest( $desc, 
        sub {
        	local $Test::Builder::Level = $Test::Builder::Level + 4;
            if ( @{ $self->{packets} } == 1 ) {
                local $msg = shift @{ $self->{packets} };
                while ( my ( $k, $v ) = each(%$hash) ) {
                    print Dumper [ $k, $v ];
                    print "[" . ref($v) . "]\n";
                    if ( ref($v) eq 'CODE' ) {
                        print Dumper $msg;
                        $tb->ok( $v->( $msg->{$k} ), $k );
                    }
                    else {
                        $tb->is_eq( $msg->{$k}, $v, $k );
                    }
                }
            }
            else {
                $tb->is_eq( scalar @{ $self->{packets} }, 1, "Received one message" );
            }
        }
    );
}

1;
