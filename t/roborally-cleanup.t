use strict;
use warnings;
use Test::More;
use Gamed;
use Gamed::Test;
use Data::Dumper;
use Gamed::Game::RoboRally::Course;
use t::RoboRally;

cleanup(
    "Repair & Upgrade",
    before => {
        a => { x => 0, y => 0, damage => 1 },    #wrench
        b => { x => 5, y => 5, damage => 2 },    #floor
        c => { x => 7, y => 7, damage => 2 },    #upgrade
        d => { x => 1, y => 4, damage => 2 },    #flag 3
        e => { x => 9, y => 7, damage => 0 },    #flag 2
    },
    after => {
        a => { x => 0, y => 0, damage => 0 },
        b => { x => 5, y => 5, damage => 2 },
        c => { x => 7, y => 7, damage => 1, options => ['Brakes'] },
        d => { x => 1, y => 4, damage => 1 },
        e => { x => 9, y => 7, damage => 0 },
    },
    broadcast => {
        repair  => { a => 0, c => 1, d => 1 },
        options => { c => ['Brakes'] } } );

cleanup(
    'Damage related cleanup',
    before => {
        a => {
            lives     => 2,
            locked    => [ 0, 0, 1, 1, 1 ],
            registers => [ ['r90'], ['l60'], ['r70'], ['3840'], ['u20'] ],
            damage    => 10,
            active    => 0
        },
        f => {    #wrench
            x         => 11,
            y         => 11,
            damage    => 7,
            locked    => [ 0, 0, 1, 1, 1 ],
            registers => [ ['r90'], ['l60'], ['r70'], ['3840'], ['u20'] ],
        }
    },
    broadcast => { a => { locked => [], registers => [], damage => 2, active => 1 } },
    after     => {
        a => {
            lives     => 2,
            locked    => [],
            registers => [],
            damage    => 2,
            active    => 1
        },
        f => {
            x         => 11,
            y         => 11,
            damage    => 6,
            locked    => [ 0, 0, 0, 1, 1 ],
            registers => [ [], [], [], ['3840'], ['u20'] ],
        } } );

cleanup(
    'Died by falling',
    before => {
        a => { lives => 2, damage => 0, active => 0 },
        b => { lives => 1, damage => 0, active => 0 },
        c => { lives => 0, damage => 0, active => 0 }
    },
    broadcast =>
      { a => { damage => 2, active => 1 }, b => { damage => 2, active => 1 }, c => { damage => 0, active => 1 } },
    after => {
        a => { lives => 2, active => 1, damage => 2 },
        b => { lives => 1, active => 1, damage => 2 },
        c => { lives => 0, damage => 0, active => 0 } } );

done_testing();

sub cleanup {
    my ( $scenario, %a ) = @_;
    subtest $scenario => sub {
        my $p1 = Gamed::Test::Player->new('a');
        my $rally = $p1->create( 'RoboRally', 'test', { course => 'risky_exchange' } );
        $rally->{public}{bots}{a} = {};
        $rally->{public}{course}->add_bot('a');
        $p1->broadcast( { cmd => 'bot', 'bot' => 'a' } );
        for my $p (grep { $_ ne 'a' } keys %{$a{before}}) {
            my $p1 = Gamed::Test::Player->new($p);
            $p1->join('test');
            $rally->{public}{bots}{$p} = {};
            $rally->{public}{course}->add_bot($p);
            $p1->broadcast( { cmd => 'bot', 'bot' => $p } );
        }
        while ( my ( $k, $v ) = each %{ $a{before} } ) {
            my $bot = $rally->{public}{course}{pieces}{$k};
            while ( my ( $bk, $bv ) = each %$v ) {
                $bot->{$bk} = $bv;
            }
        }
        $rally->{option_cards} = bless { cards => ['Brakes'] }, 'Gamed::Object::Deck';
        $rally->{state} = undef;
        $rally->change_state('CLEANUP');
        $rally->handle( $p1, { cmd => 1 } );

        $a{broadcast}{cmd} = 'cleanup';
        $p1->got( $a{broadcast} );

        $p1->{sock}{packets} = [];
        $p1->{game} = Gamed::Lobby->new;
        delete $Gamed::instance{test};
        done_testing();
      }
}
