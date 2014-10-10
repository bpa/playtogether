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
	is( $rally->{players}{0}{private}{cards}->values, 9, "player 1 was dealt 9 cards");
	$p1->got_one( { cmd => 'programming', cards => sub { $_[0]->values == 9 } } );
	is( $rally->{players}{1}{private}{cards}->values, 9, "player 2 was dealt 9 cards");
	$p2->got_one( { cmd => 'programming', cards => sub { $_[0]->values == 9 } } );

    done();
};

sub setup {
    my $rally = $p1->create( 'RoboRally', 'test', { course => 'Checkmate' } );
	ok( defined $rally->{public}{course}, "public/course is defined");
    $p2->join('test');
    $p1->broadcast( { cmd => 'bot', 'bot' => 'twonky' } );
    $p1->broadcast( { cmd => 'ready' } );
    $p2->broadcast( { cmd => 'bot', bot => 'twitch' } );
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
