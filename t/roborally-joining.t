use strict;
use warnings;
use Test::More;
use Test::Deep;
use Gamed;
use Gamed::Test;
use Data::Dumper;

my $p1 = Gamed::Test::Player->new('1');
my $p2 = Gamed::Test::Player->new('2');
my $p3 = Gamed::Test::Player->new('3');
my $p4 = Gamed::Test::Player->new('4');

subtest 'two players' => sub {
    my $rally = $p1->create( 'RoboRally', 'test', { course => 'checkmate' } );
    ok( defined $rally->{public}{course}, "public/course is defined" );
    $p2->join('test');
    $p1->broadcast( { cmd => 'bot', 'bot' => 'twonky', player => 0 } );
    $p1->broadcast( { cmd => 'ready', player => 0 } );
    $p2->broadcast( { cmd => 'bot', bot   => 'twitch', player => 1 } );
    $p2->game( { cmd => 'ready', player => 1 } );
    broadcast( $rally, { cmd => 'ready', player => 1 }, "Got ready" );
    is( $rally->{state}{name}, 'Programming' );

    for my $p ( values %{ $rally->{players} } ) {
        is( $p->{public}{bot}{lives}, 3 );
    }

    done();
};

subtest "Bot choice is final" => sub {
    my $rally = $p1->create( 'RoboRally', 'test', { course => 'checkmate' } );
    $p1->broadcast( { cmd => 'bot', 'bot' => 'twonky', player => 0 } );
    $p1->game( { cmd => 'bot', bot => 'twitch' }, { cmd => 'error', reason => 'You already chose a bot' } );

    done();
};

subtest "Can't be ready until bot chosen" => sub {
    my $rally = $p1->create( 'RoboRally', 'test', { course => 'checkmate' } );
    $p2->join('test');
    $p1->game( { cmd => 'ready' }, { cmd => 'error', reason => 'No bot chosen' } );

    done();
};

sub done {
    for my $p ( $p1, $p2, $p3, $p4 ) {
        $p->{sock}{packets} = [];
        $p->{game} = Gamed::Lobby->new;
    }
    delete $Gamed::instance{test};
    done_testing();
}

done_testing();
