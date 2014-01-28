use strict;
use warnings;

use Test::More;
use Gamed;
use Gamed::Test;

my ( $rook, $n, $e, $s, $w ) = game( [qw/n e s w/], { game => 'Rook' } );
ok( defined $rook, "Game created" );
is( $rook->{state}->name, 'Dealing' );

done_testing;

1;
