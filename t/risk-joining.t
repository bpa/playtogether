use strict;
use warnings;
use Test::More;
use Gamed;
use Gamed::Test;

my $p1 = Gamed::Test::Player->new('1');
my $p2 = Gamed::Test::Player->new('2');
my $p3 = Gamed::Test::Player->new('3');
my $p4 = Gamed::Test::Player->new('4');

subtest 'start 2 player game' => sub {
    my $risk = $p1->create( 'SpeedRisk', 'test', { board => 'Classic' } );
    is( $p1->{in_game_id}, 0 );
    is( ~~ keys %{ $risk->{players} }, 1 );

    ok( !$risk->{players}{0}{public}{ready} );
    $p1->game( { cmd => 'ready' }, error 'Not enough players' );
    ok( !$risk->{players}{0}{public}{ready} );

    $p2->join('test');
    is( $p2->{in_game_id}, 1 );
    is( ~~ keys %{ $risk->{players} }, 2 );

    #Toggle ready state
    $p1->broadcast( { cmd => 'ready' }, { cmd => 'ready', player => 0 } );
    ok( $risk->{players}{0}{public}{ready}, "N is ready" );
    $p1->broadcast( { cmd => 'not ready' }, { cmd => 'not ready', player => 0 } );
    ok( !$risk->{players}{0}{public}{ready}, "N is not ready" );
    $p1->broadcast( { cmd => 'ready' }, { cmd => 'ready', player => 0 } );
    ok( $risk->{players}{0}{public}{ready}, "N is ready" );

    #Everyone is finally ready
    $p2->game( { cmd => 'ready' } );
    broadcast( $risk, { cmd => 'ready', player => 1 } );
    broadcast( $risk, { cmd => 'armies' } );
    broadcast( $risk, { cmd => 'placing' } );
    is( $risk->{state}{name}, 'Placing' );

    done();
};

subtest 'drop/rejoin and start game' => sub {
    my $risk = $p1->create( 'SpeedRisk', 'test', { board => 'Classic' } );
    $p2->join('test');
    $p3->join('test');
    $p1->quit;
    is( ref( $p1->{game} ), 'Gamed::Lobby' );
    playing( $risk, 2 );
    $p1->join('test');
    playing( $risk, 3 );
    is( $p1->{in_game_id}, 3, "Re-joining players get a new id" );
    $p4->join('test');
    playing( $risk, 4 );
    is( scalar( keys( %{ $risk->{players} } ) ), 4 );

    $p1->quit;
    is( scalar( keys( %{ $risk->{players} } ) ), 3 );
    $p4->quit;
    is( scalar( keys( %{ $risk->{players} } ) ), 2 );
    $p2->broadcast( { cmd => 'ready' } );
    $p3->game( { cmd => 'ready' } );
    broadcast( $risk, { cmd => 'ready' } );
    broadcast( $risk, { cmd => 'armies' } );
    broadcast( $risk, { cmd => 'placing' } );
    is( $risk->{state}{name}, 'Placing' );

    done();
};

subtest 'dropping unready player can start game' => sub {
    my $risk = $p1->create( 'SpeedRisk', 'test', { board => 'Classic' } );
    $p2->join('test');
    $p2->broadcast( { cmd => 'ready' }, { cmd => 'ready', player => 1 }, 'P2 is ready' );
    $p1->quit;
    is( $risk->{state}{name}, 'WaitingForPlayers', 'Need enough players' );

    $p1->join('test');
    $p3->join('test');
    playing( $risk, 3 );
    $p3->broadcast( { cmd => 'ready' }, { cmd => 'ready', player => 3 } );
    $p1->quit;

    broadcast( $risk, { cmd => 'armies' } );
    broadcast( $risk, { cmd => 'placing' } );
    is( $risk->{state}{name}, 'Placing' );

    done();
};

subtest 'game starts automatically with enough players' => sub {
    my $risk = $p1->create( 'SpeedRisk', 'test', { board => 'Classic' } );
    for my $p ( 2 .. 6 ) {
        my $player = Gamed::Test::Player->new($p);
        $player->join('test');
    }
    broadcast( $risk, { cmd => 'armies' } );
    broadcast( $risk, { cmd => 'placing' } );
    is( $risk->{state}{name}, 'Placing' );

    done();
};

subtest 'game destroyed when all players leave' => sub {
    my $risk = $p1->create( 'SpeedRisk', 'test', { board => 'Classic' } );
    is( ~~ keys %{ $risk->{players} }, 1 );
    $p1->quit;
    is_deeply(
        [ { cmd => 'delete', game => 'SpeedRisk', name => 'test' } ],
        $p1->{sock}{packets},
        "Game deleted message"
    );
    ok( !defined $Gamed::instance{test}, "Game was deleted" );

    done();
};

subtest 'get random theme on join' => sub {
    my $risk = $p1->create( 'SpeedRisk', 'test', { board => 'Classic' } );
    $p2->join('test');
    $p3->join('test');
    $p4->join('test');
    my %theme;
    map { $theme{ $_->{public}{theme} } = () } values %{ $risk->{players} };
    is( ~~ keys %theme, 4, "Got 4 different themes" );

    done();
};

subtest 'set theme' => sub {
    my $risk = $p1->create( 'SpeedRisk', 'test', { board => 'Classic' } );
    $p2->join('test');

    $risk->{public}{themes}{test} = ();
    $p1->game( { cmd => 'theme', theme => undef },  error => 'Invalid theme' );
    $p1->game( { cmd => 'theme', theme => "none" }, error => 'Invalid theme' );
    $p1->broadcast( { cmd => 'theme', theme => "test" }, { cmd => 'theme', theme => 'test', player => 0 } );
    $p2->game( { cmd => 'theme', theme => "test" }, error => 'Invalid theme' );

    done();
};

sub playing {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $risk, $players ) = @_;
    is( scalar( keys %{ $risk->{players} } ), $players );
    is( scalar( keys %{ $risk->{ids} } ),     $players );
}

sub done {
    for my $p ( $p1, $p2, $p3, $p4 ) {
        $p->{sock}{packets} = ();
        $p->{game} = Gamed::Lobby->new;
    }
    delete $Gamed::instance{test};
    done_testing();
}
done_testing();
