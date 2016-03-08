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
    my $risk = $p1->create( 'SpeedRisk', 'test', { board => 'Classic' }, { player => { theme => ignore() } } );
    $p2->join('test', { player => { theme => ignore() } });
    $p1->broadcast( { cmd => 'ready' }, { cmd => 'ready', player => 0 } );
    $p2->game( { cmd => 'ready' } );
    broadcast( $risk, { cmd => 'ready', player => 1 }, "Got ready" );
    is( $risk->{state}{name}, 'Placing' );

    my %player_countries;
    $p1->got( { cmd => 'armies', armies => ignore() } );
    $p1->got_one( { cmd => 'placing', countries => ignore() } );
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
        is( $player_countries{$p},           14, "Each player has 14 countries" );
        is( $risk->{players}{$p}{countries}, 14, "Game says each player has 14 countries" );
    }
    is( $risk->{players}{0}{private}{armies}, 26, "Player 1 has 26 armies to place" );
    is( $risk->{players}{1}{private}{armies}, 26, "Player 2 has 26 armies to place" );
    is( $risk->{players}{d}{private}{armies}, 0,  "Dummy player placed all armies" );

    done();
};

subtest 'all ready starts game' => sub {
    my $risk = placing_with_3();

    $p1->broadcast( { cmd => 'ready' }, { cmd => 'ready', player => 0 } );
    $p2->broadcast( { cmd => 'ready' }, { cmd => 'ready', player => 1 } );
    $p3->game( { cmd => 'ready' } );
    broadcast( $risk, { cmd => 'ready', player => 2 } );
    broadcast( $risk, { cmd => 'playing' } );
    is( $risk->{state}{name}, 'Playing' );

    done();
};

subtest 'can start with dropped player' => sub {
    my $risk = placing_with_3();

    $p1->quit();
    $p2->broadcast( { cmd => 'ready' }, { cmd => 'ready', player => 1 } );
    $p3->game( { cmd => 'ready' } );
    broadcast( $risk, { cmd => 'ready', player => 2 } );
    broadcast( $risk, { cmd => 'playing' } );
    is( $risk->{state}{name}, 'Playing' );

    done();
};

subtest 'drop unready player starts game' => sub {
    my $risk = placing_with_3();

    $p2->broadcast( { cmd => 'ready' }, { cmd => 'ready', player => 1 } );
    $p3->broadcast( { cmd => 'ready' }, { cmd => 'ready', player => 2 } );
    $p1->quit();

    broadcast( $risk, { cmd => 'playing' } );
    is( $risk->{state}{name}, 'Playing' );

    done();
};

subtest 'last player wins by default' => sub {
    my $risk = placing_with_3();
    $p1->quit();
    $p2->game( { cmd => 'quit' } );

    broadcast( $risk, { cmd => 'victory', player => 2 } );
    broadcast( $risk, { cmd => 'quit',    player => 1 } );
    is( $risk->{state}{name}, 'GameOver' );

    done();
};

subtest 'place' => sub {
    my $risk = placing_with_3();

    $risk->{public}{countries}[0]{owner} = 0;
    $risk->{public}{countries}[1]{owner} = 1;

    $p1->game( { cmd => 'place', country => 0, armies => 0 }, { cmd => 'error', reason => 'Not enough armies' } );

    $p1->game( { cmd => 'place', country => 0 }, { cmd => 'error', reason => 'Not enough armies' } );

    $p1->game( { cmd => 'place', country => 0, armies => 1 } );
    $p1->got( { cmd => 'armies', armies => 25 } );
    broadcast( $risk, { cmd => 'country', country => { id => 0, armies => 2, owner => '0' } } );
    is( $risk->{players}{0}{private}{armies}, 25 );

    $p1->game( { cmd => 'place', country => 0, armies => 5 } );
    $p1->got( { cmd => 'armies', armies => 20 } );
    broadcast( $risk, { cmd => 'country', country => { id => 0, armies => 7, owner => '0' } } );
    is( $risk->{players}{0}{private}{armies}, 20 );

    $p1->game( { cmd => 'place', country => 0, armies => -1 }, { cmd => 'error', reason => 'Not enough armies' } );

    $p1->game( { cmd => 'place', country => 0, armies => 21 }, { cmd => 'error', reason => 'Not enough armies' } );

    $p1->game( { cmd => 'place', country => 1, armies => 1 }, { cmd => 'error', reason => 'Not owner' } );

    $p1->game( { cmd => 'place', armies => 1 }, { cmd => 'error', reason => 'No country specified' } );

    done();
};

done_testing();

sub placing_with_3 {
    my $risk = $p1->create( 'SpeedRisk', 'test', { board => 'Classic' }, { player => { theme => ignore() } } );
    $p2->join('test', { player => { theme => ignore() } });
    $p3->join('test', { player => { theme => ignore() } });
    $p1->broadcast( { cmd => 'ready' }, { cmd => 'ready', player => 0 } );
    $p2->broadcast( { cmd => 'ready' }, { cmd => 'ready', player => 1 } );
    $p3->game( { cmd => 'ready' } );
    broadcast( $risk, { cmd => 'ready', player => 2 } );
    broadcast( $risk, { cmd => 'armies', armies => ignore() } );
    broadcast( $risk, { cmd => 'placing', countries => ignore() } );
    is( $risk->{state}{name}, 'Placing' );
    return $risk;
}

sub done {
    for my $p ( $p1, $p2, $p3, $p4 ) {
        $p->{sock}{packets} = [];
        $p->{game} = Gamed::Lobby->new;
    }
    delete $Gamed::instance{test};
    done_testing();
}
