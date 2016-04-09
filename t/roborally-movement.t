use strict;
use warnings;
use Test::More;
use Gamed;
use Gamed::Test;
use Data::Dumper;
use Gamed::Game::RoboRally::Course;
use t::RoboRally;

my $course = Gamed::Game::RoboRally::Course->new('checkmate');
$course->add_bot( 'a' );
$course->place( $course->{course}{pieces}{a}, 1 );
is_deeply( $course->{course}{pieces}{a}, ( bot( 'a', 5, 14, N, { archive => [ 5, 14 ] } ) )[1] );

$course->add_bot( 'b' );
$course->place( $course->{course}{pieces}{b}, 2 );
is_deeply( $course->{course}{pieces}{a}, ( bot( 'a', 5, 14, N, { archive => [ 5, 14 ] } ) )[1] );
is_deeply( $course->{course}{pieces}{b}, ( bot( 'b', 6, 14, N, { archive => [ 6, 14 ] } ) )[1] );

move(
    scenario => 'Rotate Right',
    register => 1,
    cards    => [ [ 'a', ['r100'] ] ],
    actions  => [ [ { piece => 'a', rotate => 'r' } ] ],
    before   => { bot('a', 5, 14, N) },
    after    => { bot('a', 5, 14, E) } );

move(
    scenario => 'Rotate Left',
    register => 1,
    cards    => [ [ 'a', ['l100'] ] ],
    actions  => [ [ { piece => 'a', rotate => 'l' } ] ],
    before   => { bot('a', 5, 14, N) },
    after    => { bot('a', 5, 14, W) } );

move(
    scenario => 'U-Turn',
    register => 1,
    cards    => [ [ 'a', ['u100'] ] ],
    actions  => [ [ { piece => 'a', rotate => 'u' } ] ],
    before   => { bot('a', 5, 14, N) },
    after    => { bot('a', 5, 14, S) } );

move(
    scenario => 'Backwards',
    register => 1,
    cards    => [ [ 'a', ['b100'] ] ],
    actions  => [ [ { piece => 'a', move => 1, dir => 2 } ] ],
    before   => { bot('a', 5, 14, N) },
    after    => { bot('a', 5, 15, N) } );

move(
    scenario => 'Move 1',
    register => 1,
    cards    => [ [ 'a', ['1100'] ] ],
    actions  => [ [ { piece => 'a', move => 1, dir => 0 } ] ],
    before   => { bot('a', 5, 14, N) },
    after    => { bot('a', 5, 13, N) } );

move(
    scenario => 'Move 2',
    register => 1,
    cards    => [ [ 'a', ['2100'] ] ],
    actions  => [ [ { piece => 'a', move => 2, dir => 0 } ] ],
    before   => { bot('a', 5, 14, N) },
    after    => { bot('a', 5, 12, N) } );

move(
    scenario => 'Move 3',
    register => 1,
    cards    => [ [ 'a', ['3100'] ] ],
    actions  => [ [ { piece => 'a', move => 3, dir => 0 } ] ],
    before   => { bot('a', 5, 14, N) },
    after    => { bot('a', 5, 11, N) } );

move(
    scenario => 'Moves are ordered',
    register => 1,
    cards    => [ [ 'a', ['1100'] ], [ 'b', ['2200'] ] ],
    actions  => [ [ { piece => 'b', move => 2, dir => 0 } ], [ { piece => 'a', move => 1, dir => 0 } ] ],
    before   => { bot('a', 5, 14, N), bot('b', 6, 14, N) },
    after    => { bot('a', 5, 13, N), bot('b', 6, 12, N) } );

move(
    scenario => 'Move 3 into wall 2 away',
    register => 1,
    cards    => [ [ 'a', ['3100'] ] ],
    actions  => [ [ { piece => 'a', move => 2, dir => 0 } ] ],
    before   => { bot('a', 2, 14, N) },
    after    => { bot('a', 2, 12, N) } );

move(
    scenario => 'Move 3 into wall 1 away',
    register => 1,
    cards    => [ [ 'a', ['3100'] ] ],
    actions  => [ [ { piece => 'a', move => 1, dir => 0 } ] ],
    before   => { bot('a', 2, 13, N) },
    after    => { bot('a', 2, 12, N) } );

move(
    scenario => "Can't move into wall",
    register => 1,
    cards    => [ [ 'a', ['3100'] ] ],
    actions  => [],
    before   => { bot('a', 2, 12, N) },
    after    => { bot('a', 2, 12, N) } );

move(
    scenario => "Fall in pit",
    register => 1,
    cards    => [ [ 'a', ['3100'] ] ],
    actions  => [ [ { piece => 'a', move => 1, dir => 3, die => 'fall' } ] ],
    before   => { bot('a', 9, 6, W) },
    after    => {} );

move(
    scenario => "Fall off board n",
    register => 1,
    cards    => [ [ 'a', ['2100'] ] ],
    actions  => [ [ { piece => 'a', move => 1, dir => 0, die => 'fall' } ] ],
    before   => { bot('a', 0, 0, N) },
    after    => {} );

move(
    scenario => "Fall off board w",
    register => 1,
    cards    => [ [ 'a', ['2100'] ] ],
    actions  => [ [ { piece => 'a', move => 1, dir => 3, die => 'fall' } ] ],
    before   => { bot('a', 0, 0, W) },
    after    => {} );

move(
    scenario => "Fall off board s",
    register => 1,
    cards    => [ [ 'a', ['2100'] ] ],
    actions  => [ [ { piece => 'a', move => 1, dir => 2, die => 'fall' } ] ],
    before   => { bot('a', 11, 15, S) },
    after    => {} );

move(
    scenario => "Fall off board e",
    register => 1,
    cards    => [ [ 'a', ['2100'] ] ],
    actions  => [ [ { piece => 'a', move => 1, dir => 1, die => 'fall' } ] ],
    before   => { bot('a', 11, 15, E) },
    after    => {} );

move(
    scenario => "Push bot",
    register => 1,
    cards    => [ [ 'a', ['1100'] ] ],
    actions  => [ [ { piece => 'a', move => 1, dir => 1 }, { piece => 'b', move => 1, dir => 1 } ] ],
    before   => { bot('a', 0, 0, E), bot('b', 1, 0, S) },
    after    => { bot('a', 1, 0, E), bot('b', 2, 0, S) }
);

move(
    scenario => "Push bot off board",
    register => 1,
    cards    => [ [ 'a', ['1100'] ] ],
    actions =>
      [ [ { piece => 'a', move => 1, dir => 0 }, { piece => 'b', move => 1, dir => 0, die => 'fall' } ] ],
    before => { bot('a', 0, 1, N), bot('b', 0, 0, S) },
    after  => { bot('a', 0, 0, N) } );

move(
    scenario => "Push 3 bots",
    register => 1,
    cards    => [ [ 'a', ['1100'] ] ],
    actions  => [
        [   { piece => 'a', move => 1, dir => 1 },
            { piece => 'b', move => 1, dir => 1 },
            { piece => 'c', move => 1, dir => 1 },
            { piece => 'd', move => 1, dir => 1 } ] ],
    before => {
        bot('a', 0, 0, E),
        bot('b', 1, 0, S),
        bot('c', 2, 0, W),
        bot('d', 3, 0, S) },
    after => {
        bot('a', 1, 0, E),
        bot('b', 2, 0, S),
        bot('c', 3, 0, W),
        bot('d', 4, 0, S) } );

move(
    scenario => "Push 3 bots with gaps",
    register => 1,
    cards    => [ [ 'a', ['3100'] ] ],
    actions  => [
        [   { piece => 'a', move => 3, dir => 1 },
            { piece => 'b', move => 3, dir => 1 },
            { piece => 'c', move => 2, dir => 1 },
            { piece => 'd', move => 1, dir => 1 } ] ],
    before => {
        bot('a', 0, 0, E),
        bot('b', 1, 0, S),
        bot('c', 3, 0, W),
        bot('d', 5, 0, S) },
    after => {
        bot('a', 3, 0, E),
        bot('b', 4, 0, S),
        bot('c', 5, 0, W),
        bot('d', 6, 0, S) } );

move(
    scenario => "Push bots with pit shielding 2nd",
    register => 1,
    cards    => [ [ 'a', ['3100'] ] ],
    actions  => [
        [   { piece => 'a', move => 2, dir => 2, die => 'fall' },
            { piece => 'b', move => 1, dir => 2, die => 'fall' } ] ],
    before => {
        bot('a', 5, 5, S),
        bot('b', 5, 6, E),
        bot('c', 5, 8, W),
        bot('d', 5, 9, N), },
    after => {
        bot('c', 5, 8, W),
        bot('d', 5, 9, N) } );

move(
    scenario => "Push bot column into wall",
    register => 1,
    cards    => [ [ 'a', ['3100'] ] ],
    actions  => [ [ { piece => 'a', move => 1, dir => 2 }, { piece => 'b', move => 1, dir => 2 } ] ],
    before   => {
        bot('a', 6, 5, S),
        bot('b', 6, 6, E),
        bot('c', 6, 8, W),
        bot('d', 6, 9, N), },
    after => {
        bot('a', 6, 6, S),
        bot('b', 6, 7, E),
        bot('c', 6, 8, W),
        bot('d', 6, 9, N) } );

move(
    scenario => "Can't push archive markers or flags",
    register => 1,
    cards    => [ [ 'a', ['3100'] ] ],
    actions  => [ [ { piece => 'a', move => 3, dir => 2 } ] ],
    before   => {
        bot('a', 0, 0, S, { archive => [ 0, 2 ] }),
        flag(1, 0, 1) },
    after => {
        bot('a', 0, 3, S, { archive => [ 0, 2 ] }),
        flag(1, 0, 1) } );

sub move {
    my %a = @_;
    subtest $a{scenario} => sub {
        my ( %pieces, @bots );
        $course->{pieces} = $a{before};
	my @cards = map { [ $a{before}{$_->[0]} => $_->[1] ] } @{$a{cards}};
        my $actions = $course->do_movement( $a{register}, \@cards );
        is_deeply( $actions, $a{actions} );
        while ( my ( $piece, $data ) = each %{ $a{after} } ) {
            is_deeply( $course->{pieces}{$piece}, $data, "$piece final position" );
        }
        done_testing();
      }
}

done_testing();
