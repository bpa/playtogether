use strict;
use warnings;
use Test::More;
use Test::Deep;
use Gamed;
use Gamed::Test;
use Data::Dumper;
use t::RoboRally;

execute(
    'checkmate',
    'Normal movement',
    [   [ 'hammer_bot',  0, 15, N, '1200' ],
        [ 'hulk_x90',    1, 15, N, '2300' ],
        [ 'spin_bot',    2, 15, N, '3400' ],
        [ 'squash_bot',  3, 15, N, 'r220' ],
        [ 'trundle_bot', 4, 15, N, 'l210' ],
        [ 'twitch',      5, 15, N, 'u50' ],
        [ 'twonky',      6, 14, N, 'b100' ] ],
    [
        {   cmd     => 'execute',
            phase   => 'movement',
            actions => [
                [ { piece => 'spin_bot', move => 3, dir => 0 } ],
                [ { piece => 'hulk_x90', move => 2, dir => 0 } ],
                [ { piece => 'squash_bot',  rotate => "r" } ],
                [ { piece => 'trundle_bot', rotate => "l" } ],
                [ { piece => 'hammer_bot',  move   => 1, dir => 0 } ],
                [ { piece => 'twonky',      move   => 1, dir => 2 } ],
                [ { piece => 'twitch',      rotate => "u" } ] ] },
        { cmd => 'execute', actions => [], phase => 'express_conveyors' },
        { cmd => 'execute', actions => [], phase => 'conveyors' },
        { cmd => 'execute', actions => [], phase => 'gears' },
        { cmd => 'execute', actions => [], phase => 'lasers' }, ],
    [qw/movement express_conveyors conveyors gears lasers/],
    [qw/movement express_conveyors conveyors gears lasers/],
    [qw/movement express_conveyors conveyors gears lasers/],
    [qw/movement express_conveyors conveyors gears lasers/], );

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
            $p->[0]->broadcast( { cmd => 'bot', 'bot' => $p->[1] }, { cmd => 'bot', bot => $p->[1], player => ignore() } );
        }
        for my $p (@$setup) {
            $p->[0]->game( { cmd => 'ready' } );
            broadcast( $rally, { cmd => 'ready', player => $p->[0]{in_game_id} }, "Got ready" );
        }

        broadcast( $rally, { cmd => 'pieces', pieces => ignore() } );
        broadcast_one( $rally, { cmd => 'programming', cards => ignore() } );
        is( $rally->{state}{name}, 'Programming' );

        for my $p (@$setup) {
            my $player = $rally->{players}{ $p->[0]{in_game_id} };
            my $piece  = $rally->{public}{course}{pieces}{ $p->[1] };
            $piece->{x} = $p->[2];
            $piece->{y} = $p->[3];
            $piece->{o} = $p->[4];
            my @cards = map { [$_] } $player->{private}{cards}->values;
            unshift @cards, [ @$p[ 5 .. $#$p ] ];
            $player->{private}{cards}->add( @$p[ 5 .. $#$p ] );
            $p->[0]->game( { cmd => 'program', registers => [ @cards[ 0 .. 4 ] ] }, { cmd => 'program', registers => ignore() } );
            $p->[0]->game( { cmd => 'ready' } );
            broadcast( $rally, { cmd => 'ready', player => $p->[0]{in_game_id} }, "Got ready" );
        }

        for my $register (@expected) {
            for my $phase (@$register) {
                if ( ref($phase) ) {
                    broadcast( $rally, $phase );
                }
                else {
                    broadcast( $rally, { cmd => 'execute', phase => $phase, actions => ignore() } );
                }
            }
        }

        delete $Gamed::instance{test};
        done_testing();
      }
}

done_testing();
