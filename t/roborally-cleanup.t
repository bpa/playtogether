use strict;
use warnings;
use Test::More;
use Gamed;
use Gamed::Test;
use Data::Dumper;
use Gamed::Game::RoboRally::Course;
use t::RoboRally;

cleanup(
    'Damage related cleanup',
    before => {
        a => {
            lives     => 2,
            locked    => [ 0, 0, 1, 1, 1 ],
            registers => [ ['r90'], ['l60'], ['r70'], ['3840'], ['u20'] ],
            damage    => 10,
            active    => 0
        }
    },
    cleanup => { a => { locked => [], registers => [], damage => 2, active => 1 } },
    after   => {
        a => {
            lives     => 2,
            locked    => [],
            registers => [],
            damage    => 2,
            active    => 1
        } } );

cleanup(
    'Died by falling',
    before => {
        a => { lives => 2, damage => 0, active => 0 },
        b => { lives => 1, damage => 0, active => 0 },
        c => { lives => 0, damage => 0, active => 0 }
    },
    cleanup =>
      { a => { damage => 2, active => 1 }, b => { damage => 2, active => 1 }, c => { damage => 0, active => 1 } },
    after => {
        a => { lives => 2, active => 1, damage => 2 },
        b => { lives => 1, active => 1, damage => 2 },
        c => { lives => 0, damage => 0, active => 0 } } );

cleanup(
    "Repair & Upgrade",
    before => {
        a => { x => 0, y => 0, damage => 1 },    #wrench
        b => { x => 5, y => 5, damage => 2 },    #floor
        c => { x => 7, y => 7, damage => 2 },    #upgrade
        d => { x => 1, y => 4, damage => 2 },    #flag 3
        e => { x => 9, y => 7, damage => 0 },    #flag 2
        f => {                                   #wrench
            x         => 11,
            y         => 11,
            damage    => 7,
            locked    => [ 0, 0, 1, 1, 1 ],
            registers => [ ['r90'], ['l60'], ['r70'], ['3840'], ['u20'] ],
        }
    },
    after => {
        a => { x => 0, y => 0, damage => 0 },
        b => { x => 5, y => 5, damage => 2 },
        c => { x => 7, y => 7, damage => 1, options => ['Brakes'] },
        d => { x => 1, y => 4, damage => 1 },
        e => { x => 9, y => 7, damage => 0 },
        f => {
            x         => 11,
            y         => 11,
            damage    => 6,
            locked    => [ 0, 0, 0, 1, 1 ],
            registers => [ [], [], [], ['3840'], ['u20'] ],
        }
    },
    broadcast => {
        repair  => { a => 0, c => 1, d => 1, f => 1 },
        options => { c => ['Brakes'] } } );

done_testing();

sub cleanup {
    my ( $scenario, %a ) = @_;
    subtest $scenario => sub {
        my $rally = Gamed::Game::RoboRally::Course->new('risky_exchange');
        #$rally->{state}->on_enter_state($rally);
        $rally->{option_cards} = bless { cards => ['Brakes'] }, 'Gamed::Object::Deck';
        SKIP: {
            skip "Tests not implemented", 1;
            fail();
        }
        done_testing();
      }
}
