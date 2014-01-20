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

    ok( !$risk->{players}{0}{ready} );
    $p1->game( { cmd => 'ready' }, error 'Not enough players' );
    ok( !$risk->{players}{0}{ready} );

    $p2->join('test');
    is( $p2->{in_game_id}, 1 );
    is( ~~ keys %{ $risk->{players} }, 2 );

    $p1->broadcast( { cmd => 'ready' }, { cmd => 'ready', player => 0 } );
    ok( $risk->{players}{0}{ready}, "N is ready");
    $p1->broadcast( { cmd => 'not ready' }, { cmd => 'not ready', player => 0 } );
    ok( !$risk->{players}{0}{ready}, "N is not ready" );
    $p1->broadcast( { cmd => 'ready' }, { cmd => 'ready', player => 0 } );
    ok( $risk->{players}{0}{ready}, "N is ready" );

    $p2->broadcast( { cmd => 'ready' }, { cmd => 'ready', player => 1 } );
    $risk->broadcast( { state => 'Placing' } );
    like( ref( $risk->{state} ), qr/Placing/ );

    delete $Gamed::game_instances{test};
    done_testing();
};

done_testing();
