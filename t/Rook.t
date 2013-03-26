use strict;
use warnings;

use Test::More;
use Gamed;
use Gamed::Test;
use Data::Dumper;

my ( $rook, $n, $e, $s, $w ) = game( 'Rook', 'test', [qw/n e s w/] );
ok( defined $rook, "Game created" );
like( ref( $rook->{state} ), qr/Dealing/ );

done_testing;

1;
