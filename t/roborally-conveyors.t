use strict;
use warnings;
use Test::More;
use Gamed;
use Gamed::Test;
use Data::Dumper;
use Gamed::Game::RoboRally::Course;
use t::RoboRally;

my $course = Gamed::Game::RoboRally::Course->new('risky_exchange');

conveyor(
    scenario => "Normal conveyor movement",
    before   => { bot( 'a', 8, 5, N ), bot( 'b', 7, 6, S ) },
    after    => { bot( 'a', 7, 5, N ), bot( 'b', 8, 6, S ) },
    actions  => [ { piece => 'a', move => 1, dir => 3 }, { piece => 'b', move => 1, dir => 1 } ] );

express(
    scenario => "Normal express conveyor movement",
    before   => { bot( 'a', 7, 5, N ), bot( 'b', 7, 6, S ) },
    after    => { bot( 'a', 7, 5, N ), bot( 'b', 8, 6, S ) },
    actions => [ { piece => 'b', move => 1, dir => 1 } ] );

conveyor(
    scenario => "Non movement",
    before   => { bot( 'a', 0, 0, N ), flag( 1, 0, 0 ) },
    after    => { bot( 'a', 0, 0, N ), flag( 1, 0, 0 ) },
    actions  => undef );

conveyor(
    scenario => "Conveyed onto floor",
    before   => { bot( 'a', 7, 5, N ) },
    after    => { bot( 'a', 6, 5, N ) },
    actions  => [ { piece => 'a', move => 1, dir => 3 } ] );

conveyor(
    scenario => "Conveyed off board",
    before   => { bot( 'a', 3, 0, N ) },
    after    => { dead( 'a', 2) },
    actions  => [ { piece => 'a', move => 1, dir => 0, die => 'fall' } ] );

conveyor(
    scenario => "Two bots move while next to each other",
    before   => { bot( 'a', 8, 5, N ), bot( 'b', 9, 5, S ) },
    after    => { bot( 'a', 7, 5, N ), bot( 'b', 8, 5, S ) },
    actions  => [ { piece => 'a', move => 1, dir => 3 }, { piece => 'b', move => 1, dir => 3 } ] );

conveyor(
    scenario => "Two bots next to eachother move, one onto floor",
    before   => { bot( 'a', 7, 5, N ), bot( 'b', 8, 5, S ) },
    after    => { bot( 'a', 6, 5, N ), bot( 'b', 7, 5, S ) },
    actions  => [ { piece => 'a', move => 1, dir => 3 }, { piece => 'b', move => 1, dir => 3 } ] );

conveyor(
    scenario => "Can't push bot",
    before   => { bot( 'a', 6, 5, N ), bot( 'b', 7, 5, S ) },
    after    => { bot( 'a', 6, 5, N ), bot( 'b', 7, 5, S ) },
    actions  => undef );

conveyor(
    scenario => "Line of bots blocked by one",
    before   => { bot( 'a', 0, 3, N ), bot( 'b', 1, 3, S ), bot( 'c', 2, 3, E ), bot( 'd', 3, 3, W ) },
    after    => { bot( 'a', 0, 3, N ), bot( 'b', 1, 3, S ), bot( 'c', 2, 3, E ), bot( 'd', 3, 3, W ) },
    actions  => undef );

$course->{tiles}[0][2] = { t => 'conveyor', o => 2, w => 0 };    #Add a conveyor into a pit
conveyor(
    scenario => "Conveyed into pit",
    before   => { bot( 'a', 2, 0, N ) },
    after    => {},
    actions  => [ { piece => 'a', move => 1, dir => 2, die => 'fall' } ] );

#Add a conveyor opposing
$course->{tiles}[3][3] = { t => 'conveyor', o => 3, w => 0 };
conveyor(
    scenario => "Won't move onto conveyor moving in opposite direction",
    before   => { bot( 'a', 2, 3, N ) },
    after    => { bot( 'a', 2, 3, N ) },
    actions  => undef );

#Add walls to stop movment
$course->{tiles}[0][3]{w}  = 1;
$course->{tiles}[1][10]{w} = 2;
conveyor(
    scenario => "Won't move through wall in same tile",
    before   => { bot( 'a', 3, 0, N ) },
    after    => { bot( 'a', 3, 0, N ) },
    actions  => undef );

conveyor(
    scenario => "Won't move through wall in next tile over",
    before   => { bot( 'a', 11, 1, N ) },
    after    => { bot( 'a', 11, 1, N ) },
    actions  => undef );

#Reverse a conveyor so it pushes into a common spot
$course->{tiles}[5][4]{o} = 1;
conveyor(
    scenario => "Don't move two bots into the same space",
    before   => { bot( 'a', 4, 5, N ), bot( 'b', 5, 4, N ) },
    after    => { bot( 'a', 4, 5, N ), bot( 'b', 5, 4, N ) },
    actions  => undef );
$course = Gamed::Game::RoboRally::Course->new('risky_exchange');

conveyor(
    scenario => "Rotate left",
    before   => { bot( 'a', 10, 14, N ) },
    after    => { bot( 'a', 9, 14, W ) },
    actions  => [ { piece => 'a', move => 1, dir => 3, rotate => 'l' } ] );

conveyor(
    scenario => "Rotate right",
    before   => { bot( 'a', 9, 14, N ) },
    after    => { bot( 'a', 9, 15, E ) },
    actions  => [ { piece => 'a', move => 1, dir => 2, rotate => 'r' } ] );

#Add conveyors around a normal turning conveyor
$course->{tiles}[14][3] = { t => 'conveyor', o => 3, w => 0 };
$course->{tiles}[15][1] = { t => 'conveyor', o => 1, w => 0 };
conveyor(
    scenario => "No rotation when coming from side",
    before   => { bot( 'a', 3, 14, N ) },
    after    => { bot( 'a', 2, 14, N ) },
    actions  => [ { piece => 'a', move => 1, dir => 3 } ] );

conveyor(
    scenario => "No rotation when coming from back",
    before   => { bot( 'a', 1, 15, N ) },
    after    => { bot( 'a', 2, 15, N ) },
    actions  => [ { piece => 'a', move => 1, dir => 1 } ] );

#Add a two directional turning conveyor
$course->{tiles}[0][10] = { t => 'conveyor',  o => 2, w => 0 };
$course->{tiles}[1][9]  = { t => 'conveyor',  o => 1, w => 0 };
$course->{tiles}[1][10] = { t => 'conveyor^', o => 0, w => 0 };
$course->{tiles}[1][11] = { t => 'conveyor',  o => 3, w => 0 };
$course->{tiles}[2][10] = { t => 'conveyor',  o => 0, w => 0 };

conveyor(
    scenario => "Rotate right when coming from right",
    before   => { bot( 'a', 11, 1, N ) },
    after    => { bot( 'a', 10, 1, E ) },
    actions  => [ { piece => 'a', move => 1, dir => 3, rotate => 'r' } ] );

conveyor(
    scenario => "Rotate left when coming from left",
    before   => { bot( 'a', 9, 1, N ) },
    after    => { bot( 'a', 10, 1, W ) },
    actions  => [ { piece => 'a', move => 1, dir => 1, rotate => 'l' } ] );

conveyor(
    scenario => "No rotation when coming from back",
    before   => { bot( 'a', 10, 2, N ) },
    after    => { bot( 'a', 10, 1, N ) },
    actions  => [ { piece => 'a', move => 1, dir => 0 } ] );

conveyor(
    scenario => "No movement when coming from front",
    before   => { bot( 'a', 10, 0 ) },
    after    => { bot( 'a', 10, 0 ) },
    actions  => undef );
$course = Gamed::Game::RoboRally::Course->new('risky_exchange');

conveyor(
    scenario => "Flags and archive markers move through bots",
    before   => { bot( 'a', 3, 3, N ), flag( 1, 2, 3 ), archive ('a', 2, 3) },
    after    => { bot( 'a', 3, 3, N ), flag( 1, 3, 3 ), archive ('a', 3, 3) },
    actions  => [ { piece => 'a_archive', move => 1, dir => 1 }, { piece => 'flag_1', move => 1, dir => 1 } ] );

conveyor(
    scenario => "Flags move through bot column",
    before   => { bot( 'a', 3, 3, N ), bot( 'b', 2, 3, N ), flag( 1, 1, 3 ) },
    after    => { bot( 'a', 3, 3, N ), bot( 'b', 2, 3, N ), flag( 1, 2, 3 ) },
    actions => [ { piece => 'flag_1', move => 1, dir => 1 } ] );

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
        $course->{pieces} = $a{before};
        my $actions = $course->$phase();
        @{ $actions->[0] } = sort { $a->{piece} cmp $b->{piece} } @{ $actions->[0] } if $actions->[0];
        is_deeply( $actions, [ $a{actions} ? $a{actions} : () ] );
        while ( my ( $piece, $data ) = each %{ $a{after} } ) {
            is_deeply( $course->{pieces}{$piece}, $data, "$piece final position" );
        }
        done_testing();
      }
}

done_testing();
