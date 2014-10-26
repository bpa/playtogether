use strict;
use warnings;
use Test::More;
use Gamed;
use Gamed::Test;
use Data::Dumper;

execute(
    'Checkmate',
    'Normal movement',
    [   [ 0, 15, 'n', '1200'],
        [ 1, 15, 'n', '2300'],
        [ 2, 15, 'n', '3400'],
        [ 3, 15, 'n', 'r220'],
        [ 4, 15, 'n', 'l210'],
        [ 5, 15, 'n', 'u50'],
        [ 6, 14, 'n', 'b100'] ],
    [
        {   phase   => 'movement',
            actions => [
                { player => 2, move   => 2, dir => "n" },
                { player => 1, move   => 1, dir => "n" },
                { player => 3, rotate => "r" },
                { player => 4, rotate => "l" },
                { player => 0, move   => 1, dir => "n" },
                { player => 6, move   => 1, dir => "s" },
                { player => 5, rotate => "u" } ]
        },
        { phase => 'express' },
        { phase => 'conveyors' },
        { phase => 'gears' },
        { phase => 'lasers' },
    ]);

sub execute {
    my ( $course, $scenario, $setup, $expected ) = @_;
	subtest $scenario => sub {
		my @bots = qw/hammer_bot hulk_x90 spin_bot squash_bot trundle_bot twitch twonky zoom_bot/;
		for my $id ( 0 .. $#$setup ) {
			unshift @{$setup->[$id]}, Gamed::Test::Player->new($id);
		}

		my $rally = $setup->[0][0]->create( 'RoboRally', 'test', { course => $course } );
		ok( defined $rally->{public}{course}, "public/course is defined" );

		for my $p ( @$setup ) {
			$p->[0]->join('test');
			$p->[0]->broadcast( { cmd => 'bot', 'bot' => shift(@bots) } );
		}
		for my $p ( @$setup ) {
			$p->[0]->game( { cmd => 'ready' } );
			broadcast( $rally, { cmd => 'ready', player => $p->[0]{in_game_id} }, "Got ready" );
		}

		broadcast( $rally, { cmd => 'pieces' } );
		broadcast_one( $rally, { cmd => 'programming' } );
		is( $rally->{state}{name}, 'Programming' );

		for my $p ( @$setup ) {
			my @cards = map { [$_] } $rally->{players}{$p->[1]}{private}{cards}->values;
			unshift @cards, [@$p[4,]];
			$rally->{players}{$p->[1]}{private}{cards}->add( @$p[4,] );
			$p->[0]->game( { cmd => 'program', registers => [@cards[0..4]] }, { cmd => 'program' } );
			$p->[0]->game( { cmd => 'ready' } );
			broadcast( $rally, { cmd => 'ready', player => $p->[0]{in_game_id} }, "Got ready" );
		}

		for my $phase ( @$expected ) {
			my $msg = $setup->[0][0]{sock}{packets}[0];
    		Gamed::Test::broadcast( $rally, { cmd => 'execute', phase => $phase->{phase} } );
			is_deeply( $msg, $phase );
		}

		delete $Gamed::instance{test};
		done_testing();
	}
}

done_testing();
