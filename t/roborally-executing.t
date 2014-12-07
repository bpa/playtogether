use strict;
use warnings;
use Test::More;
use Gamed;
use Gamed::Test;
use Data::Dumper;

execute(
    'checkmate',
    'Normal movement',
    [   [ 'hammer_bot',  0, 15, 0, '1200' ],
        [ 'hulk_x90',    1, 15, 0, '2300' ],
        [ 'spin_bot',    2, 15, 0, '3400' ],
        [ 'squash_bot',  3, 15, 0, 'r220' ],
        [ 'trundle_bot', 4, 15, 0, 'l210' ],
        [ 'twitch',      5, 15, 0, 'u50' ],
        [ 'twonky',      6, 14, 0, 'b100' ]
    ],
    [
        {   cmd     => 'execute',
            phase   => 'movement',
            actions => [
                [ { piece => 'spin_bot',    move => 3, dir => 0 } ],
                [ { piece => 'hulk_x90',    move => 2, dir => 0 } ],
                [ { piece => 'squash_bot',  rotate => "r" } ],
                [ { piece => 'trundle_bot', rotate => "l" } ],
                [ { piece => 'hammer_bot',  move   => 1, dir => 0 } ],
                [ { piece => 'twonky',      move   => 1, dir => 2 } ],
                [ { piece => 'twitch',      rotate => "u" } ] ]
        },
        { cmd => 'execute', actions => [], phase => 'express_conveyors' },
        { cmd => 'execute', actions => [], phase => 'conveyors' },
        { cmd => 'execute', actions => [], phase => 'gears' },
        { cmd => 'execute', actions => [], phase => 'lasers' },
    ],
    [qw/movement express_conveyors conveyors gears lasers/],
    [qw/movement express_conveyors conveyors gears lasers/],
    [qw/movement express_conveyors conveyors gears lasers/],
    [qw/movement express_conveyors conveyors gears lasers/],
);

sub execute {
    my ( $course, $scenario, $setup, @expected ) = @_;
    subtest $scenario => sub {
        for my $id ( 0 .. $#$setup ) {
            unshift @{ $setup->[$id] }, Gamed::Test::Player->new($id);
        }

        my $rally = $setup->[0][0]->create( 'RoboRally', 'test', { course => $course } );
        ok( defined $rally->{public}{course}, "public/course is defined" );

        for my $p (@$setup) {
            $p->[0]->join('test');
            $p->[0]->broadcast( { cmd => 'bot', 'bot' => $p->[1] } );
        }
        for my $p (@$setup) {
            $p->[0]->game( { cmd => 'ready' } );
            broadcast( $rally, { cmd => 'ready', player => $p->[0]{in_game_id} }, "Got ready" );
        }

        broadcast( $rally, { cmd => 'pieces' } );
        broadcast_one( $rally, { cmd => 'programming' } );
        is( $rally->{state}{name}, 'Programming' );

        for my $p (@$setup) {
            my $player = $rally->{players}{ $p->[0]{in_game_id} };
            my $piece  = $rally->{course}{pieces}{ $p->[1] };
            $piece->{x} = $p->[2];
            $piece->{y} = $p->[3];
            $piece->{o} = $p->[4];
            my @cards = map { [$_] } $player->{private}{cards}->values;
            unshift @cards, [ @$p[ 5 .. $#$p ] ];
            $player->{private}{cards}->add( @$p[ 5 .. $#$p ] );
            $p->[0]->game( { cmd => 'program', registers => [ @cards[ 0 .. 4 ] ] }, { cmd => 'program' } );
            $p->[0]->game( { cmd => 'ready' } );
            broadcast( $rally, { cmd => 'ready', player => $p->[0]{in_game_id} }, "Got ready" );
        }

        for my $register (@expected) {
            for my $phase (@$register) {
                my $msg = $setup->[0][0]{sock}{packets}[0];
                if ( ref($phase) ) {
                	broadcast( $rally, { cmd => 'execute', phase => $phase->{phase} } );
                    is_deeply( $phase, $msg );
                }
                else {
                	broadcast( $rally, { cmd => 'execute', phase => $phase } );
                    is( $msg->{phase}, $phase );
                }
            }
        }

        delete $Gamed::instance{test};
        done_testing();
      }
}

done_testing();
