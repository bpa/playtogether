use strict;
use warnings;

use Test::More;
use Gamed;
use Gamed::Test;
use Data::Dumper;

my ( $n, $e, $s, $w ) = game( 'Rook', 'test', 'n', 'e', 's', 'w' );
my $rook = $Gamed::game_instances{test};
ok( defined $rook, "Game created" );
like( ref( $rook->{state} ), qr/Dealing/ );

$e->game( { do => 'deal' }, { reason => 'Not your turn' }, 'Deal out of turn' );
$n->game( { do => 'deal' } );
is( $rook->{leader}, 0, 'North starts the deal' );

broadcast_one(
    $rook,
    {   hand => sub { grep( /(\d+[RGBY])|0/, @{ $_[0] } ) == 10 }
    },
    'Hand Dealt'
);
for my $s ( 0 .. 3 ) {
    is( grep ( $_->isa('Gamed::Object::Card'), @{ $rook->{seat}[$s]{cards} } ), 10, "Game kept record of cards dealt to player" );
}
is( grep ( $_->isa('Gamed::Object::Card'), @{ $rook->{nest} } ), 5, "5 cards in the nest" );

like( ref( $rook->{state} ), qr/Bidding/, "Now bidding" );

$e->game( { bid => 100 }, { reason => 'Not your turn' },         "Bid out of turn" );
$n->game( { bid => 50 },  { reason => 'Bidding starts at 100' }, "Bid too low" );
$n->game( { bid => 205 }, { reason => 'Bidding max is 200' },    "Bid too high" );

$n->game( { bid => 100 } );
broadcast_one( $rook, { bid => 100 }, 'bid was broadcast' );

done_testing;

1;
