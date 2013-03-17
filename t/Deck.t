use strict;
use warnings;
use Test::More;
use Gamed::Object;

my $rook1 = Gamed::Object::Deck::Rook->new->reset;
is(scalar(@{$rook1->{cards}}), 57, 'Deck has 57 cards');

my $rook2= Gamed::Object::Deck::Rook->new->reset;
$rook2->shuffle;
isnt(eq_array($rook1->{cards}, $rook2->{cards}), "Shuffle mixed cards");

my $rook = Gamed::Object::Deck::Rook->new('partnership')->reset;
is(scalar(@{$rook->{cards}}), 45, 'Partnership deck has 45 cards');

#$7G
done_testing;

1;
