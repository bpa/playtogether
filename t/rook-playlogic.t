use strict;
use warnings;

use Test::More;
use Gamed;
use Gamed::Test;
use Gamed::Object;
use Data::Dumper;

my $rook = bless { public => { trump => 'R' } }, 'Gamed::Game::Rook';
my $logic = Gamed::Game::Rook::PlayLogic->new;
my $hand  = bag(qw/1R 1G 5G 10Y 9Y/);

good_play( '1R', [], 'Lead valid card' );
fail_play( '1B', [], 'Lead invalid card' );
good_play( '1R', ['5R'], 'Follow suit' );
fail_play( '1R', ['5G'], "Must follow suit" );
good_play( '1G', ['5B'], "Can play anything if don't have trump" );
fail_play( '1B', ['5B'], 'Play invalid card' );

is( $logic->trick_winner( [qw/5Y 11Y 8Y/], $rook ), 1, 'High card wins' );
is( $logic->trick_winner( [qw/5Y 14Y 1Y/], $rook ), 2, 'One is high' );
is( $logic->trick_winner( [qw/5G 14Y 1Y/], $rook ), 0, 'Non suit loses' );
is( $logic->trick_winner( [qw/9G 14Y 5R/], $rook ), 2, 'Trump wins' );
is( $logic->trick_winner( [qw/9G 5R 14G/], $rook ), 1, 'Trump wins' );
is( $logic->trick_winner( [qw/9G 0_ 14G/], $rook ), 1, 'Rook is trump' );
is( $logic->trick_winner( [qw/9G 0_ 14R/], $rook ), 2, 'High trump wins' );

round_end(
    name         => 'Make bid',
    player       => 'n',
    bidder       => 'n',
    bid          => 100,
    start_points => [ 0, 0 ],
    end_points   => [ 200, 0 ],
    state        => 'Dealing',
	nest         => bag(qw/9Y 8Y 7Y 11B 12B/),
    taken        => [ [qw/1Y 1R 1B 1G 14Y 14R 14B 14G 10Y 10R 10B 10G 5Y 5R 5G 5B 0_/], [], [], [] ] );

round_end(
    name         => 'No points',
    player       => 'n',
    bidder       => 'n',
    bid          => 100,
    start_points => [ 0, 0 ],
    end_points   => [ -100, 200 ],
    state        => 'Dealing',
	nest         => bag(qw/9Y 8Y 7Y 11B 12B/),
    taken        => [ [], [qw/1Y 1R 1B 1G 14Y 14R 14B 14G 10Y 10R 10B 10G 5Y 5R 5G 5B 0_/], [], [] ] );

round_end(
    name         => 'Game over',
    player       => 'e',
    bidder       => 'e',
    bid          => 150,
    start_points => [ 450, 400 ],
    end_points   => [ 500, 550 ],
    state        => 'Game Over',
	nest         => bag(qw/9Y 8Y 7Y 11B 12B/),
    taken        => [ [qw/1Y 1B 10Y 10B/], [qw/1R 1G 14Y 14R 14B 14G 10R 10G 5Y 5R 5G 5B 0_/], [], [] ] );

round_end(
    name         => 'Tie Game',
    player       => 'w',
    bidder       => 'w',
    bid          => 150,
    start_points => [ 450, 350 ],
    end_points   => [ 500, 500 ],
    state        => 'Dealing',
	nest         => bag(qw/9Y 8Y 7Y 11B 12B/),
    taken        => [ [qw/1Y 1B 10Y 10B/], [qw/1R 1G 14Y 14R 14B 14G 10R 10G 5Y 5R 5G 5B 0_/], [], [] ] );

round_end(
    name         => 'More tricks gives 20pt bonus',
    player       => 's',
    bidder       => 'e',
    bid          => 135,
    start_points => [ 0, 0 ],
    end_points   => [ 65, 135 ],
    state        => 'Dealing',
	nest         => bag(qw/9Y 8Y 7Y 11B 12B/),
    taken        => [ [qw/1Y 1B 10Y 5B/], [qw/1R 1G 14Y 14R 14B 14G 10R 10G 10B 5Y 5R 5G 0_/], [qw/6R 6G 6B 6Y 7R 7G 7B 7Y 8R 8G 8B 8Y/], [] ] );

round_end(
    name         => 'Last player gets points from nest',
    player       => 'w',
    bidder       => 'w',
    bid          => 150,
    start_points => [ 0, 0 ],
    end_points   => [ 40, 160 ],
    state        => 'Dealing',
	nest         => bag(qw/5Y 10Y 5B 11B 12B/),
    taken        => [ [qw/1Y 1B 10B/], [qw/1R 1G 14Y 14R 14B 14G 10R 10G 5R 5G 0_/], [], [] ] );

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
		public => {
        	points => $opts{start_points} || [ 0, 0 ],
			player => $opts{player},
			bidder => $opts{bidder},
			bid    => $opts{bid},
			trump  => 'R',
		},
		nest => $opts{nest},
		seats => [qw/n e s w/],
        players => {
			n => { taken => $opts{taken}[0] },
			e => { taken => $opts{taken}[1] },
			s => { taken => $opts{taken}[2] },
			w => { taken => $opts{taken}[3] },
		}
      },
      'Gamed::Game::Rook';

    $logic->on_round_end($rook);
    Gamed::States::after_star($rook);
    my $name = $opts{name};
    is_deeply( $rook->{public}{points}, $opts{end_points}, "$name - end points" );
    is( $rook->{state}{name}, $opts{state}, "$name - state" );
}
