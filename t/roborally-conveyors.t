use strict;
use warnings;
use Test::More;
use Gamed;
use Gamed::Test;
use Data::Dumper;
use Gamed::Game::RoboRally::Course;

my $course = Gamed::Game::RoboRally::Course->new('risky_exchange');

conveyor(
    scenario => "Normal conveyor movement",
    before   => { a => { x => 8, y => 5, o => 0, solid => 1 }, b => { x => 7, y => 6, o => 2, solid => 1 } },
    actions => [ { piece => 'a', move => 1, dir => 3 }, { piece => 'b', move => 1, dir => 1 } ],
    final => { a => { x => 7, y => 5, o => 0, solid => 1 }, b => { x => 8, y => 6, o => 2, solid => 1 } } );

express(
    scenario => "Normal express conveyor movement",
    before   => { a => { x => 7, y => 5, o => 0, solid => 1 }, b => { x => 7, y => 6, o => 2, solid => 1 } },
    actions => [ { piece => 'b', move => 1, dir => 1 } ],
    final => { a => { x => 7, y => 5, o => 0, solid => 1 }, b => { x => 8, y => 6, o => 2, solid => 1 } } );

conveyor(
    scenario => "Conveyed onto floor",
    before   => { a => { x => 7, y => 5, o => 0, solid => 1 } },
    actions => [ { piece => 'a', move => 1, dir => 3 } ],
    final => { a => { x => 6, y => 5, o => 0, solid => 1 } } );

conveyor(
    scenario => "Conveyed off board",
    before   => { a => { x => 3, y => 0, o => 0, solid => 1 } },
    actions  => [ { piece => 'a', move => 1, dir => 0, die => 'fall' } ],
    final    => {} );

conveyor(
    scenario => "Two bots move while next to each other",
    before   => { a => { x => 8, y => 5, o => 0, solid => 1 }, b => { x => 9, y => 5, o => 2, solid => 1 } },
    actions => [ { piece => 'a', move => 1, dir => 3 }, { piece => 'b', move => 1, dir => 3 } ],
    final => { a => { x => 7, y => 5, o => 0, solid => 1 }, b => { x => 8, y => 5, o => 2, solid => 1 } },
);

conveyor(
    scenario => "Two bots next to eachother move, one onto floor",
    before   => { a => { x => 7, y => 5, o => 0, solid => 1 }, b => { x => 8, y => 5, o => 2, solid => 1 } },
    actions  => [ { piece => 'a', move => 1, dir => 3 }, { piece => 'b', move => 1, dir => 3 } ],
    final    => { a => { x => 6, y => 5, o => 0, solid => 1 }, b => { x => 7, y => 5, o => 2, solid => 1 } },
);

conveyor(
    scenario => "Can't push bot",
    before   => { a => { x => 6, y => 5, o => 0, solid => 1 }, b => { x => 7, y => 5, o => 2, solid => 1 } },
    actions  => [],
    final    => { a => { x => 6, y => 5, o => 0, solid => 1 }, b => { x => 7, y => 5, o => 2, solid => 1 } },
);

conveyor(
    scenario => "Line of bots blocked by one",
    before   => {
        a => { x => 0, y => 3, o => 0, solid => 1 },
        b => { x => 1, y => 3, o => 2, solid => 1 },
        c => { x => 2, y => 3, o => 1, solid => 1 },
        d => { x => 3, y => 3, o => 3, solid => 1 },
    },
    actions => [],
    final   => {
        a => { x => 0, y => 3, o => 0, solid => 1 },
        b => { x => 1, y => 3, o => 2, solid => 1 },
        c => { x => 2, y => 3, o => 1, solid => 1 },
        d => { x => 3, y => 3, o => 3, solid => 1 },
    } );

$course->{tiles}[0][2] = { t => 'conveyor', o => 2, w => 0 };    #Add a conveyor into a pit
conveyor(
    scenario => "Conveyed into pit",
    before   => { a => { x => 2, y => 0, o => 0, solid => 1 } },
    actions  => [ { piece => 'a', move => 1, dir => 2, die => 'fall' } ],
    final    => {} );

#Add a conveyor opposing
$course->{tiles}[3][3] = { t => 'conveyor', o => 3, w => 0 };
conveyor(
    scenario => "Won't move onto conveyor moving in opposite direction",
    before   => { a => { x => 2, y => 3, o => 0, solid => 1 } },
    actions  => [],
    final    => { a => { x => 2, y => 3, o => 0, solid => 1 } } );

#Add walls to stop movment
$course->{tiles}[0][3]{w} = 1;
$course->{tiles}[1][10]{w} = 2;
conveyor(
    scenario => "Won't move through wall in same tile",
    before   => { a => { x => 3, y => 0, o => 0, solid => 1 } },
    actions  => [],
    final    => { a => { x => 3, y => 0, o => 0, solid => 1 } } );

conveyor(
    scenario => "Won't move through wall in next tile over",
    before   => { a => { x => 11, y => 1, o => 0, solid => 1 } },
    actions  => [],
    final    => { a => { x => 11, y => 1, o => 0, solid => 1 } } );

#Reverse a conveyor so it pushes into a common spot
$course->{tiles}[5][4]{o} = 1;
conveyor(
    scenario => "Don't move two bots into the same space",
    before   => { a => { x => 4, y => 5, o => 0, solid => 1 }, b => { x => 5, y => 4, o => 0, solid => 1 } },
    actions  => [],
	final    => { a => { x => 4, y => 5, o => 0, solid => 1 }, b => { x => 5, y => 4, o => 0, solid => 1 } } );
$course = Gamed::Game::RoboRally::Course->new('risky_exchange');

conveyor(
    scenario => "Rotate left",
    before   => { a => { x => 10, y => 14, o => 0, solid => 1 } },
    actions  => [ { piece => 'a', move => 1, dir => 3, rotate => 'l' } ],
    final    => { a => { x => 9, y => 14, o => 3, solid => 1 } } );

conveyor(
    scenario => "Rotate right",
    before   => { a => { x => 9, y => 14, o => 0, solid => 1 } },
    actions  => [ { piece => 'a', move => 1, dir => 2, rotate => 'r' } ],
    final    => { a => { x => 9, y => 15, o => 1, solid => 1 } } );

#Add conveyors around a normal turning conveyor
$course->{tiles}[14][3] = { t => 'conveyor', o => 3, w => 0 };
$course->{tiles}[15][1] = { t => 'conveyor', o => 1, w => 0 };
conveyor(
    scenario => "No rotation when coming from side",
    before   => { a => { x => 3, y => 14, o => 0, solid => 1 } },
    actions  => [ { piece => 'a', move => 1, dir => 3 } ],
    final    => { a => { x => 2, y => 14, o => 0, solid => 1 } } );

conveyor(
    scenario => "No rotation when coming from back",
    before   => { a => { x => 1, y => 15, o => 0, solid => 1 } },
    actions  => [ { piece => 'a', move => 1, dir => 1 } ],
    final    => { a => { x => 2, y => 15, o => 0, solid => 1 } } );

#Add a two directional turning conveyor
$course->{tiles}[0][10] = { t => 'conveyor',  o => 2, w => 0 };
$course->{tiles}[1][9]  = { t => 'conveyor',  o => 1, w => 0 };
$course->{tiles}[1][10] = { t => 'conveyor^', o => 0, w => 0 };
$course->{tiles}[1][11] = { t => 'conveyor',  o => 3, w => 0 };
$course->{tiles}[2][10] = { t => 'conveyor',  o => 0, w => 0 };

conveyor(
    scenario => "Rotate right when coming from right",
    before   => { a => { x => 11, y => 1, o => 0, solid => 1 } },
    actions  => [ { piece => 'a', move => 1, dir => 3, rotate => 'r' } ],
    final    => { a => { x => 10, y => 1, o => 1, solid => 1 } } );

conveyor(
    scenario => "Rotate left when coming from left",
    before   => { a => { x => 9, y => 1, o => 0, solid => 1 } },
    actions  => [ { piece => 'a', move => 1, dir => 1, rotate => 'l' } ],
    final    => { a => { x => 10, y => 1, o => 3, solid => 1 } } );

conveyor(
    scenario => "No rotation when coming from back",
    before   => { a => { x => 10, y => 2, o => 0, solid => 1 } },
    actions  => [ { piece => 'a', move => 1, dir => 0 } ],
    final    => { a => { x => 10, y => 1, o => 0, solid => 1 } } );

conveyor(
    scenario => "No movement when coming from front",
    before   => { a => { x => 10, y => 0, o => 0, solid => 1 } },
    actions  => [],
    final    => { a => { x => 10, y => 0, o => 0, solid => 1 } } );
$course = Gamed::Game::RoboRally::Course->new('risky_exchange');

conveyor(
    scenario => "Archive markers don't move",
    before   => { a => { x => 0, y => 1, o => 0, archive => 1 } },
    actions  => [],
    final    => { a => { x => 0, y => 1, o => 0, archive => 1 } } );

conveyor(
    scenario => "Flags move through bots",
    before   => { a => { x => 3, y => 3, o => 0, solid => 1 }, flag_1 => { x => 2, y => 3, o => 0 } },
    actions  => [ { piece => 'flag_1', move => 1, dir => 1 } ],
    final    => { a => { x => 3, y => 3, o => 0, solid => 1 }, flag_1 => { x => 3, y => 3, o => 0 } } );

conveyor(
    scenario => "Flags move through bot column",
    before   => {
        a      => { x => 3, y => 3, o => 0, solid => 1 },
        b      => { x => 2, y => 3, o => 0, solid => 1 },
        flag_1 => { x => 1, y => 3, o => 0 }
    },
    actions => [ { piece => 'flag_1', move => 1, dir => 1 } ],
    final   => {
        a      => { x => 3, y => 3, o => 0, solid => 1 },
        b      => { x => 2, y => 3, o => 0, solid => 1 },
        flag_1 => { x => 2, y => 3, o => 0 } } );

sub conveyor {
    run_test( 'do_conveyors', @_ );
}

sub express {
    run_test( 'do_express_conveyors', @_ );
}

sub run_test {
    my ( $phase, %a ) = @_;
    subtest $a{scenario} => sub {
        my ( %pieces, @bots );
        while ( my ( $k, $v ) = each( %{ $a{before} } ) ) {
            $v->{id} = $k;
        }
        while ( my ( $k, $v ) = each( %{ $a{final} } ) ) {
            $v->{id} = $k;
        }
        $course->{pieces} = $a{before};
        my $actions = $course->$phase();
        @{$actions->[0]} = sort { $a->{piece} cmp $b->{piece} } @{$actions->[0]} if $actions->[0];
        is_deeply( $actions, [ $a{actions} ] );
        while ( my ( $piece, $data ) = each %{ $a{final} } ) {
            is_deeply( $course->{pieces}{$piece}, $data, "$piece final position" );
        }
        done_testing();
      }
}

done_testing();
