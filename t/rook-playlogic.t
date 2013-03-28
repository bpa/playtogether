use strict;
use warnings;

use Test::More;
use Gamed;
use Gamed::Test;
use Gamed::Util;
use Data::Dumper;

my $rook = bless { trump => 'R', }, 'Gamed::Game';
my $logic = Gamed::Game::Rook::PlayLogic->new;
my $hand = bag(qw/1R 1G 5G 10Y 9Y/);

good_play( '1R', [], 'Lead valid card' );
fail_play( '1B', [], 'Lead invalid card' );
good_play( '1R', ['5R'], 'Follow suit' );
fail_play( '1R', ['5G'], "Don't follow suit" );

done_testing;

sub good_play {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
	ok($logic->is_valid_play( shift, shift, $hand, $rook ), shift);
}

sub fail_play {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
	ok(!$logic->is_valid_play( shift, shift, $hand, $rook ), shift);
}
