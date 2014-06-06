use strict;
use warnings;

use Test::More;
use Gamed;
use Gamed::Test;
use Gamed::Object;
use Data::Dumper;

my $rook  = bless { trump => 'R', }, 'Gamed::Game::Rook';
my $logic = Gamed::Game::Rook::PlayLogic->new;
my $hand  = bag(qw/1R 1G 5G 10Y 9Y/);

good_play( '1R', [], 'Lead valid card' );
fail_play( '1B', [], 'Lead invalid card' );
good_play( '1R', ['5R'], 'Follow suit' );
fail_play( '1R', ['5G'], "Must follow suit" );
good_play( '1G', ['5B'], "Can play anything if don't have trump" );

is( $logic->trick_winner( [qw/5Y 11Y 8Y/], $rook ), 1, 'High card wins' );
is( $logic->trick_winner( [qw/5Y 14Y 1Y/], $rook ), 2, 'One is high' );
is( $logic->trick_winner( [qw/5G 14Y 1Y/], $rook ), 0, 'Non suit loses' );
is( $logic->trick_winner( [qw/9G 14Y 5R/], $rook ), 2, 'Trump wins' );
is( $logic->trick_winner( [qw/9G 5R 14G/], $rook ), 1, 'Trump wins' );
is( $logic->trick_winner( [qw/9G 0_ 14G/], $rook ), 1, 'Rook is trump' );
is( $logic->trick_winner( [qw/9G 0_ 14R/], $rook ), 2, 'High trump wins' );

round_end(
    name         => 'Make bid',
    bidder       => 0,
    bid          => 100,
    start_points => [ 0, 0 ],
    end_points   => [ 200, 0 ],
    state        => 'Dealing',
    taken        => [ [qw/1Y 1R 1B 1G 14Y 14R 14B 14G 10Y 10R 10B 10G 5Y 5R 5G 5B 0_/], [], [], [] ] );

round_end(
    name         => 'No points',
    start_points => [ 0, 0 ],
    end_points   => [ -100, 200 ],
    bidder       => 0,
    bid          => 100,
    state        => 'Dealing',
    taken        => [ [], [qw/1Y 1R 1B 1G 14Y 14R 14B 14G 10Y 10R 10B 10G 5Y 5R 5G 5B 0_/], [], [] ] );

round_end(
    name         => 'Game over',
    start_points => [ 450, 400 ],
    end_points   => [ 500, 550 ],
    bidder       => 1,
    bid          => 150,
    state        => 'Game Over',
    taken        => [ [qw/1Y 1B 10Y 10B/], [qw/1R 1G 14Y 14R 14B 14G 10R 10G 5Y 5R 5G 5B 0_/], [], [] ] );

round_end(
    name         => 'Tie Game',
    start_points => [ 450, 350 ],
    end_points   => [ 500, 500 ],
    bidder       => 3,
    bid          => 150,
    state        => 'Dealing',
    taken        => [ [qw/1Y 1B 10Y 10B/], [qw/1R 1G 14Y 14R 14B 14G 10R 10G 5Y 5R 5G 5B 0_/], [], [] ] );

done_testing;

sub good_play {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    ok( $logic->is_valid_play( shift, shift, $hand, $rook ), shift );
}

sub fail_play {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    ok( !$logic->is_valid_play( shift, shift, $hand, $rook ), shift );
}

sub round_end {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my %opts = @_;
    my $rook = bless {
        states => {
            DEALING   => bless( { name => 'Dealing' },   'Gamed::State' ),
            GAME_OVER => bless( { name => 'Game Over' }, 'Gamed::State' ),
        },
        state => bless( { name => 'start' }, 'Gamed::State' ),
        points => $opts{start_points} || [ 0, 0 ],
        bidder => $opts{bidder},
        bid    => $opts{bid},
        seat => [ map { { taken => $_ } } @{$opts{taken}} ],
      },
      'Gamed::Game::Rook';
	
    $logic->on_round_end($rook);
	Gamed::States::after_star($rook);
	my $name = $opts{name};
	is_deeply($rook->{points}, $opts{end_points}, "$name - end points");
    is($rook->{state}{name}, $opts{state}, "$name - state");
}
