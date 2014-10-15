use strict;
use warnings;
use Test::More;
use Gamed;
use Gamed::Test;
use Data::Dumper;

my $p1 = Gamed::Test::Player->new('1');
my $p2 = Gamed::Test::Player->new('2');
my $p3 = Gamed::Test::Player->new('3');
my $p4 = Gamed::Test::Player->new('4');

subtest 'two players' => sub {
    my $rally = $p1->create( 'RoboRally', 'test', { course => 'Checkmate' } );
	ok( defined $rally->{public}{course}, "public/course is defined");
    $p2->join('test');
    $p1->broadcast( { cmd => 'bot', 'bot' => 'twonky' } );
    $p1->broadcast( { cmd => 'ready' } );
    $p2->broadcast( { cmd => 'bot', bot => 'twitch' } );
    $p2->game( { cmd => 'ready' } );
    broadcast( $rally, { cmd => 'ready', player => 1 }, "Got ready" );
    is( $rally->{state}{name}, 'Programming' );

    done();
};

subtest "Bot choice is final" => sub {
    my $rally = $p1->create( 'RoboRally', 'test', { course => 'Checkmate' } );
    $p1->broadcast( { cmd => 'bot', 'bot' => 'twonky' } );
    $p1->game( { cmd => 'bot', bot => 'twitch' }, { reason => 'You already chose a bot' } );

    done();
};

subtest "Can't be ready until bot chosen" => sub {
    my $rally = $p1->create( 'RoboRally', 'test', { course => 'Checkmate' } );
    $p2->join('test');
    $p1->game( { cmd => 'ready'}, { reason => 'No bot chosen' } );

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
