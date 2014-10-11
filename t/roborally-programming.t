use strict;
use warnings;
use Test::More;
use Gamed;
use Gamed::Test;
use Data::Dumper;

my $p1 = Gamed::Test::Player->new('1');
my $p2 = Gamed::Test::Player->new('2');

subtest 'two players' => sub {
    my $rally = setup();
    is( $rally->{players}{0}{private}{cards}->values, 9, "player 1 was dealt 9 cards" );
    $p1->got_one(
        {   cmd   => 'programming',
            cards => sub { $_[0]->values == 9 }
        } );
    is( $rally->{players}{1}{private}{cards}->values, 9, "player 2 was dealt 9 cards" );
    $p2->got_one(
        {   cmd   => 'programming',
            cards => sub { $_[0]->values == 9 }
        } );

    done();
};

subtest 'programming' => sub {
    my $rally = setup();
    $p1->reset;
    $p2->reset;
    my @hand = $rally->{players}{0}{private}{cards}->values;
    $p1->game( { cmd => 'program', registers => [ [ $hand[0] ] ] }, { lock => 0 } );
    is_deeply( $rally->{players}{0}{private}{registers}, [ [ $hand[0] ] ] );
    $p1->game( { cmd => 'program', registers => [] }, { lock => 0 } );
    is_deeply( $rally->{players}{0}{private}{registers}, [] );
    $p1->game( { cmd => 'program', registers => [ $hand[0] ] }, { reason => "Invalid program" } );
    $p1->game( { cmd => 'program', registers => ['3100'] }, { reason => "Invalid program" } );
    $p1->game( { cmd => 'program', registers => [ [ '3100' ] ] }, { reason => "Invalid card" } );
    $p1->game( { cmd => 'program', registers => [ [ $hand[0], $hand[1] ] ] }, { reason => "Invalid program" } );
    $p1->game( { cmd => 'program', registers => [ [ $hand[0] ], [ $hand[1] ], [ $hand[2] ], [ $hand[3] ], [ $hand[4] ], [ $hand[5] ] ] }, { reason => "Invalid program" } );
    $p1->game( { cmd => 'program', registers => [ [ $hand[0] ], [ $hand[1] ], [ $hand[2] ], [ $hand[3] ], [ $hand[4] ] ] }, { lock => 0 } );
    $p1->game( { cmd => 'program', registers => [ [ $hand[0] ], [ $hand[1] ], [ $hand[2] ], [ $hand[3] ], [ $hand[4] ] ], lock => 1 }, { lock => 1 } );
    $p1->game( { cmd => 'program', registers => [ [ $hand[0] ] ] }, { reason => 'Registers are already programmed' } );

    done();
};

subtest 'locked registers' => sub {
    my $rally = setup();
	$p1->reset;
	$p2->reset;

    $rally->{players}{0}{public}{damage} = 5;
    $rally->{players}{0}{public}{locked} = ['u20'];
    $rally->{players}{1}{public}{damage} = 2;
	$rally->{state}->on_enter_state($rally);

    $p1->got_one(
        {   cmd   => 'programming',
            cards => sub { $_[0]->values == 4 }
        } );
    $p2->got_one(
        {   cmd   => 'programming',
            cards => sub { $_[0]->values == 7 }
        } );
	
	done();
};

subtest 'time up' => sub {
    my $rally = setup();
	$p1->reset;
	$p2->reset;

	done();
};

subtest 'time up with locked' => sub {
    my $rally = setup();
	$p1->reset;
	$p2->reset;

	done();
};

sub setup {
    my $rally = $p1->create( 'RoboRally', 'test', { course => 'Checkmate' } );
    ok( defined $rally->{public}{course}, "public/course is defined" );
    $p2->join('test');
    $p1->broadcast( { cmd => 'bot', 'bot' => 'twonky' } );
    $p1->broadcast( { cmd => 'ready' } );
    $p2->broadcast( { cmd => 'bot', bot   => 'twitch' } );
    $p2->game( { cmd => 'ready' } );
    broadcast( $rally, { cmd => 'ready', player => 1 }, "Got ready" );
    is( $rally->{state}{name}, 'Programming' );

    return $rally;
}

sub done {
    for my $p ( $p1, $p2 ) {
        $p->{sock}{packets} = [];
        $p->{game} = Gamed::Lobby->new;
    }
    delete $Gamed::instance{test};
    done_testing();
}

done_testing();
