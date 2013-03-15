use Test::More;
use Gamed;
use Gamed::Test;
use Data::Dumper;

my ($n,$e,$s,$w) = game('Rook','test','n','e','s','w');
my $rook = $Gamed::game_instances{test};
ok(defined $rook, "Game created");
like(ref($rook->{state}), qr/Rook::Bidding/);

done_testing;

1;
