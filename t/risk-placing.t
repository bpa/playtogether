use strict;
use warnings;
use Test::More;
use Gamed;
use Gamed::Test;

my $p1 = Gamed::Test::Player->new('1');
my $p2 = Gamed::Test::Player->new('2');
my $p3 = Gamed::Test::Player->new('3');
my $p4 = Gamed::Test::Player->new('4');

subtest 'two players' => sub {
    my $risk = $p1->create( 'SpeedRisk', 'test', { board => 'Classic' } );
    $p2->join('test');
    $p1->broadcast( { cmd => 'ready' } );
    $p2->game( { cmd => 'ready' } );
    broadcast( $risk, { cmd => 'ready', player => 1 }, "Got ready" );
    like( ref( $risk->{state} ), qr/Placing/ );

    my %player_armies;
    $p1->got_one( { cmd => 'state' } );
    my $msg = pop @{ $p2->{sock}{packets} };
    is( ~~ @{ $msg->{countries} }, 42 );
    for my $c ( 0 .. 42 ) {
        ok( $msg->{countries}[$c]{owner} < 3, "Owned by player" );
        is( $msg->{countries}[$c]{armies}, 1, "Country starts with one army" );
        $player_armies{ $msg->{countries}[$c]{owner} }++;
    }
    for my $p ( 0 .. 2 ) {
        is( $player_armies{$p}, 14, "Each player has 14 armies" );
        is( $risk->{players}{$p}{countries},
            14, "Game says each player has 14 armies" );
    }
    is( $risk->{players}{0}{armies}, 26, "Player 1 has 26 armies to place" );
    is( $risk->{players}{1}{armies}, 26, "Player 2 has 26 armies to place" );
    is( $risk->{players}{2}{armies}, 26, "Player 3 has 26 armies to place" );

    done();
};

sub done {
    for my $p ( $p1, $p2, $p3, $p4 ) {
        $p->{sock}{packets} = ();
        delete $p->{game};
    }
    delete $Gamed::game_instances{test};
    done_testing();
}
