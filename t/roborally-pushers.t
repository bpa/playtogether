use strict;
use warnings;
use Test::More;
use Gamed;
use Gamed::Test;
use Data::Dumper;
use Gamed::Game::RoboRally::Course;
use t::RoboRally;

my $course = Gamed::Game::RoboRally::Course->new('checkmate');
$course->{tiles}[13][1] = { t => 'pusher', o => 2, w => 0, r => 21 };
$course->{tiles}[14][1] = { t => 'pusher', o => 1, w => 0, r => 10 };
$course->{tiles}[15][1] = { t => 'pusher', o => 0, w => 0, r => 1 };

pusher(
    scenario => "In phase, normal push",
	register => 2,
    before   => { bot('a', 1, 14, 1) },
    actions  => [ { piece => 'a', move => 1, dir => 1 } ],
    final    => { bot('a', 2, 14, 1) } );

pusher(
    scenario => "One out of phase",
	register => 3,
    before   => { bot('a', 1, 13, 1), bot('b', 1, 15, 3) },
    actions  => [ { piece => 'a', move => 1, dir => 2 } ],
    final    => { bot('a', 1, 14, 1), bot('b', 1, 15, 3) } );

pusher(
    scenario => "Blocked by wall",
	register => 4,
    before   => { bot('a', 1, 14, 1), bot('b', 2, 14, 3) },
    actions  => undef,
    final    => { bot('a', 1, 14, 1), bot('b', 2, 14, 3) } );

pusher(
    scenario => "Push into same tile nullifies movement",
	register => 1,
    before   => { bot('a', 1, 13, 1), bot('b', 1, 15, 3) },
    actions  => undef,
    final    => { bot('a', 1, 13, 1), bot('b', 1, 15, 3) } );

sub pusher {
    my ( %a ) = @_;
    subtest $a{scenario} => sub {
        my ( %pieces, @bots );
        $course->{pieces} = $a{before};
        my $actions = $course->do_pushers($a{register});
		@$actions = sort { $a->{piece} cmp $b->{piece} } @$actions if $actions;
		print Dumper $actions;
        is_deeply( $actions, $a{actions} );
        while ( my ( $piece, $data ) = each %{ $a{final} } ) {
            is_deeply( $course->{pieces}{$piece}, $data, "$piece final position" );
        }
        done_testing();
      }
}

done_testing();
