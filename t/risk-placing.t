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
    my $risk = $p1->create( 'SpeedRisk', 'test', { board => 'Classic' } );
    $p2->join('test');
    $p1->broadcast( { cmd => 'ready' } );
    $p2->game( { cmd => 'ready' } );
    broadcast( $risk, { cmd => 'ready', player => 1 }, "Got ready" );
    is( $risk->{state}->name, 'Placing' );

    my %player_countries;
    $p1->got( { cmd => 'armies' } );
    $p1->got_one( { cmd => 'state' } );
    my $msg = pop @{ $p2->{sock}{packets} };
    is( ~~ @{ $msg->{countries} }, 42 );
    for my $c ( 0 .. 41 ) {

        #Skip the dummy player, it will have an id of 'd' and more than one army
        if ( $msg->{countries}[$c]{owner} ne 'd' ) {
            ok( $msg->{countries}[$c]{owner} < 3, "Owned by player" );
            is( $msg->{countries}[$c]{armies}, 1, "Country starts with one army" );
        }
        $player_countries{ $msg->{countries}[$c]{owner} }++;
    }
    for my $p ( 0, 1, 'd' ) {
        is( $player_countries{$p}, 14, "Each player has 14 countries" );
        is( $risk->{players}{$p}{countries},
            14, "Game says each player has 14 countries" );
    }
    is( $risk->{players}{0}{armies}, 26, "Player 1 has 26 armies to place" );
    is( $risk->{players}{1}{armies}, 26, "Player 2 has 26 armies to place" );
    is( $risk->{players}{d}{armies}, 0,  "Dummy player placed all armies" );

    done();
};

subtest 'all ready starts game' => sub {
    my $risk = $p1->create( 'SpeedRisk', 'test', { board => 'Classic' } );
    $p2->join('test');
    $p1->broadcast( { cmd => 'ready' } );
    $p2->game( { cmd => 'ready' } );
	broadcast( $risk, { cmd   => 'ready' } );
    broadcast( $risk, { cmd   => 'armies' } );
    broadcast( $risk, { state => 'Placing' } );
    $p1->broadcast( { cmd => 'ready' } );
    $p2->game( { cmd => 'ready' } );
	broadcast( $risk, { cmd   => 'ready' } );
    broadcast( $risk, { state => 'Playing' } );
    is( $risk->{state}->name, 'Playing' );

	done();
};

done_testing();

sub done {
    for my $p ( $p1, $p2, $p3, $p4 ) {
        $p->{sock}{packets} = ();
        delete $p->{game};
    }
    delete $Gamed::game_instances{test};
    done_testing();
}
