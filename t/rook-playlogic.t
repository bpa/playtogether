use strict;
use warnings;

use Test::More;
use Gamed;
use Gamed::Test;
use Gamed::Object;
use Data::Dumper;

my $rook = bless { trump => 'R', }, 'Gamed::Game';
my $logic = Gamed::Game::Rook::PlayLogic->new;
my $hand = bag(qw/1R 1G 5G 10Y 9Y/);

good_play( '1R', [], 'Lead valid card' );
fail_play( '1B', [], 'Lead invalid card' );
good_play( '1R', ['5R'], 'Follow suit' );
fail_play( '1R', ['5G'], "Must follow suit" );
good_play( '1G', ['5B'], "Can play anything if don't have trump" );

is( $logic->trick_winner([qw/5Y 11Y 8Y/], $rook), 1, 'High card wins' );
is( $logic->trick_winner([qw/5Y 14Y 1Y/], $rook), 2, 'One is high' );
is( $logic->trick_winner([qw/5G 14Y 1Y/], $rook), 0, 'Non suit loses' );
is( $logic->trick_winner([qw/9G 14Y 5R/], $rook), 2, 'Trump wins' );
is( $logic->trick_winner([qw/9G 5R 14G/], $rook), 1, 'Trump wins' );
is( $logic->trick_winner([qw/9G 0_ 14G/], $rook), 1, 'Rook is trump' );
is( $logic->trick_winner([qw/9G 0_ 14R/], $rook), 2, 'High trump wins' );

done_testing;

sub good_play {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
	ok($logic->is_valid_play( shift, shift, $hand, $rook ), shift);
}

sub fail_play {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
	ok(!$logic->is_valid_play( shift, shift, $hand, $rook ), shift);
}
