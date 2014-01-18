use strict;
use warnings;

use Test::More;
use Gamed;
use Gamed::Test;
use Data::Dumper;

my ( $risk, $a, $b )
  = game( [ 'a', 'b' ], { game => 'SpeedRisk', board => 'Classic' } );
ok( defined $risk, "Game created" );
like( ref( $risk->{state} ), qr/Waiting/ );

done_testing;
