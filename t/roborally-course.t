use strict;
use warnings;
use Test::More;
use Gamed;
use Gamed::Test;
use Data::Dumper;
use Gamed::Game::RoboRally::Course;

my $course = Gamed::Game::RoboRally::Course->new('checkmate');
$course->add_bot( 'a', 1 );
is_deeply( $course->{course}{pieces}{a}, { x => 5, y => 14, o => 0, solid => 1 } );

$course->add_bot( 'b', 2 );
is_deeply( $course->{course}{pieces}{b}, { x => 6, y => 14, o => 0, solid => 1 } );

move(
    scenario => 'Rotate Right',
    register => 1,
    cards    => [ [ 'a', ['r100'] ] ],
    actions  => [ [ { piece => 'a', rotate => 'r' } ] ],
    before   => { a => { x => 5, y => 14, o => 0, solid => 1 } },
    final    => { a => { x => 5, y => 14, o => 1, solid => 1 } } );

move(
    scenario => 'Rotate Left',
    register => 1,
    cards    => [ [ 'a', ['l100'] ] ],
    actions  => [ [ { piece => 'a', rotate => 'l' } ] ],
    before   => { a => { x => 5, y => 14, o => 0, solid => 1 } },
    final    => { a => { x => 5, y => 14, o => 3, solid => 1 } } );

move(
    scenario => 'U-Turn',
    register => 1,
    cards    => [ [ 'a', ['u100'] ] ],
    actions  => [ [ { piece => 'a', rotate => 'u' } ] ],
    before   => { a => { x => 5, y => 14, o => 0, solid => 1 } },
    final    => { a => { x => 5, y => 14, o => 2, solid => 1 } } );

move(
    scenario => 'Backwards',
    register => 1,
    cards    => [ [ 'a', ['b100'] ] ],
    actions  => [ [ { piece => 'a', move => 1, dir => 2 } ] ],
    before   => { a => { x => 5, y => 14, o => 0, solid => 1 } },
    final    => { a => { x => 5, y => 15, o => 0, solid => 1 } } );

move(
    scenario => 'Move 1',
    register => 1,
    cards    => [ [ 'a', ['1100'] ] ],
    actions  => [ [ { piece => 'a', move => 1, dir => 0 } ] ],
    before   => { a => { x => 5, y => 14, o => 0, solid => 1 } },
    final    => { a => { x => 5, y => 13, o => 0, solid => 1 } } );

move(
    scenario => 'Move 2',
    register => 1,
    cards    => [ [ 'a', ['2100'] ] ],
    actions  => [ [ { piece => 'a', move => 2, dir => 0 } ] ],
    before   => { a => { x => 5, y => 14, o => 0, solid => 1 } },
    final    => { a => { x => 5, y => 12, o => 0, solid => 1 } } );

move(
    scenario => 'Move 3',
    register => 1,
    cards    => [ [ 'a', ['3100'] ] ],
    actions  => [ [ { piece => 'a', move => 3, dir => 0 } ] ],
    before   => { a => { x => 5, y => 14, o => 0, solid => 1 } },
    final    => { a => { x => 5, y => 11, o => 0, solid => 1 } } );

move(
    scenario => 'Moves are ordered',
    register => 1,
    cards    => [ [ 'a', ['1100'] ], [ 'b', ['2200'] ] ],
    actions  => [ [ { piece => 'b', move => 2, dir => 0 } ], [ { piece => 'a', move => 1, dir => 0 } ] ],
    before   => { a => { x => 5, y => 14, o => 0, solid => 1 }, b => { x => 6, y => 14, o => 0, solid => 1 } },
    final    => { a => { x => 5, y => 13, o => 0, solid => 1 }, b => { x => 6, y => 12, o => 0, solid => 1 } } );

move(
    scenario => 'Move 3 into wall 2 away',
    register => 1,
    cards    => [ [ 'a', ['3100'] ] ],
    actions  => [ [ { piece => 'a', move => 2, dir => 0 } ] ],
    before   => { a => { x => 2, y => 14, o => 0, solid => 1 } },
    final    => { a => { x => 2, y => 12, o => 0, solid => 1 } } );

move(
    scenario => 'Move 3 into wall 1 away',
    register => 1,
    cards    => [ [ 'a', ['3100'] ] ],
    actions  => [ [ { piece => 'a', move => 1, dir => 0 } ] ],
    before   => { a => { x => 2, y => 13, o => 0, solid => 1 } },
    final    => { a => { x => 2, y => 12, o => 0, solid => 1 } } );

move(
    scenario => "Can't move into wall",
    register => 1,
    cards    => [ [ 'a', ['3100'] ] ],
    actions  => [],
    before   => { a => { x => 2, y => 12, o => 0, solid => 1 } },
    final    => { a => { x => 2, y => 12, o => 0, solid => 1 } } );

sub move {
    my %a = @_;
    subtest $a{scenario} => sub {
        my ( %pieces, @bots );
        $course->{pieces} = $a{before};
        my $actions = $course->do_movement( $a{register}, $a{cards} );
        is_deeply( $actions, $a{actions} );
        while ( my ( $piece, $data ) = each %{ $a{final} } ) {
            is_deeply( $course->{pieces}{$piece}, $data, "$piece final position" );
        }
        done_testing();
      }
}

done_testing();