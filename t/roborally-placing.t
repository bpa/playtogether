use strict;
use warnings;
use Test::More;
use Test::Deep qw/cmp_details deep_diag ignore/;
use Gamed::Game::RoboRally::Course;
use Gamed::Game::RoboRally::Cleanup;
use File::Spec::Functions 'catdir';
use Data::Dumper;
use t::RoboRally;

$Gamed::public = catdir(qw/lib Gamed public/);

subtest 'Place bot on archive marker' => sub {
    my $available = setup(
        {   pieces  => { bot( 'b', 0, 4, E ), bot( 'c', 3, 4, W ), bot( 'd', 1, 7, N ), },
            archive => [ 1, 4 ] } );

    place_err($available, 2, 4, E, "Must place on archive");
    place_err($available, 1, 4, W, "Can't face bot next to you");
    place_err($available, 1, 4, E, "Can't face bot 2 tiles away"),
    place_err($available, 1, 4, S, "Can't face bot 3 tiles away"),
    place_ok ($available, 1, 4, N, "Can face bot 3 tiles away"),
};

subtest 'Placing on dead bot ok' => sub {
    my $available = setup(
        {   pieces  => { dead( 'a', 0, 0, 2 ) },
            archive => [ 0, 0 ] } );

    place_ok($available, 0, 0, S, "OK to place on dead bot"),
};

subtest 'Place next to archive marker' => sub {
    my $available = setup(
        {   pieces  => { bot('a', 0, 0, N) },
            archive => [ 0, 0 ] } );

    place_err($available, 0, 0, N, "Can't place on occupied tile");
    place_err($available, 1, 0, W, "Can't face bot next to you");
    place_ok ($available, 1, 0, E);
};

subtest "Blocks" => sub {
    my $available = setup( { pieces => { piece( 'b', 'block', 0, 0, N, 1, 1 ) }, archive => [ 0, 0 ] } );

    place_err($available, 0, 0, S, "Can't place on block");
    place_ok ($available, 0, 1, S, "Block makes next tier available");
    place_ok ($available, 0, 1, N, "Can face block");
};

subtest "Pit" => sub {
    my $available = setup( { pieces => { bot('b', 2, 0, N) }, archive => [ 2, 0 ] } );

    place_err($available, 2, 1, S, "Can't place on pit");
    place_ok ($available, 1, 1, S, "Next to pit is fine");
};

subtest 'Corner case with no placement options on or adjacent to archive marker' => sub {
    my $available = setup( { pieces => { bot( 'a', 0, 0, E ), bot( 'b', 0, 1, W ), bot( 'c', 1, 1, N ), bot( 'd', 1, 0, S ) }, archive => [ 0, 0 ] } );

    place_err($available, 2, 0, W, "Facing bot" );
    place_err($available, 2, 1, E, "Pit" );
    place_ok ($available, 2, 2, W );
};

subtest 'Visibility impedence' => sub {
    my $available = setup(
        {   pieces => {
                bot( 'a', 6, 14, N ),
                piece( 'b', 'block', 5, 14, N, 1, 1 ),
                bot( 'c', 5, 13, S ),
                flag( '1', 5, 14 ) },
            archive => [ 5, 15 ] } );

    place_ok($available, 5, 15, N, "Block impedes line of sight");
    place_ok($available, 5, 15, E, "Wall impedes line of sight");
    place_ok($available, 5, 15, S, "Off board is fine");
    place_ok($available, 5, 15, W, "Flag does not impede line of sight and is not a bot");
};

done_testing();

sub setup {
    my $args = shift;
    my $course = Gamed::Game::RoboRally::Course->new( 'risky_exchange' );
    while (my ($name, $bot) = each %{$args->{pieces}}) {
        $course->add_bot($name);
        $course->place($course->{pieces}{$name}, 1);
        $course->move($course->{pieces}{$name}, $bot->{x}, $bot->{y});
        $course->{pieces}{$name} = $bot;
        $course->move($bot, $bot->{x}, $bot->{y});
    }
    return { placing_options => $course->available_placements(@{$args->{archive}}) };
}

sub place_err {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ($setup, $x, $y, $o, $msg) = @_;
    my $r = Gamed::Game::RoboRally::Cleanup::valid_placement($setup, { x => $x, y => $y, o => $o });
    is(!!$r, '', $msg);
}

sub place_ok {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ($setup, $x, $y, $o, $msg) = @_;
    my $r = Gamed::Game::RoboRally::Cleanup::valid_placement($setup, { x => $x, y => $y, o => $o });
    is(!!$r, 1, $msg);
}
