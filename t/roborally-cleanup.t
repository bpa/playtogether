use strict;
use warnings;
use Test::More;
use Gamed;
use Gamed::Test;
use Data::Dumper;
use Gamed::Game::RoboRally::Course;
use t::RoboRally;

cleanup(
    'Died by damage',
    before => {
        lives     => 3,
        locked    => [ 0, 0, 1, 1, 1 ],
        registers => [ ['r90'], ['l60'], ['r70'], ['3840'], ['u20'] ],
        damage    => 10,
        active    => 0
    },
    after => {
        lives     => 2,
        locked    => [],
        registers => [],
        damage    => 2,
        active    => 1
    } );

cleanup(
    'Died by pit',
    before => {
        lives  => 3,
        damage => 0,
        active => 0
    },
    after => {
        lives  => 2,
        active => 1,
        damage => 2
    } );

cleanup(
    'Last life',
    before => {
        lives  => 1,
        active => 0
    },
    after => {
        lives  => 0,
        active => 0,
    } );

cleanup(
    'Already dead',
    before => {
        lives  => 0,
        active => 0
    },
    after => {
        lives  => 0,
        active => 0,
    } );

cleanup(
    'Power up',
    before => {
        lives   => 2,
        active  => 1,
        damage  => 1,
        powered => 0,
    },
    after => {
        lives   => 2,
        active  => 0,
        damage  => 1,
        powered => 1,
    },
);

#First death, due to pit
$rally->{players}{1}{public}{damage} = 0;
delete $rally->{board}{pieces}{twitch};

#Third and final death, due to pit
$rally->{players}{2}{public}{damage} = 4;
$rally->{players}{2}{public}{lives}  = 1;
delete $rally->{board}{pieces}{zoom_bot};

$rally->{state}->on_enter_state($rally);

for my $p ( $p1, $p2 ) {
    is( $rally->{players}{ $p->{in_game_id} }{public}{lives}, 2 );
    is_deeply( $rally->{players}{ $p->{in_game_id} }{private}{registers}, [] );
    $p->got_one( {
            cmd   => 'programming',
            cards => sub { $_[0]->values == 7 }
        } );
}
is( $rally->{players}{2}{public}{lives}, 0 );
is_deeply( $rally->{players}{2}{private}{registers}, [] );
$p3->got_one( { cmd => 'programming', cards => [] } );

done();

sub cleanup {
    my ($scenario, %a) = @_;
    subtest $scenario => sub {
        my $course = Gamed::Game::RoboRally::Course->new('risky_exchange');
    }
}
