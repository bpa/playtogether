use strict;
use warnings;

use Test::More;
use Test::Deep;
use Gamed;
use Gamed::Test;
use Data::Dumper;
use Gamed::Game::RoboRally;
use t::RoboRally;

touches(
    scenario => "Nothing",
    register => 1,
    bots     => { a => { pos => [ 5, 14 ], archive => [ 5, 15 ] } },
    messages => [] );

touches(
    scenario => "Move archives",
    register => 1,
    bots     => {
        a => { pos => [ 0,  0 ],  archive => [ 5,  15 ], flag => 0 },    #wrench
        b => { pos => [ 5,  5 ],  archive => [ 6,  15 ], flag => 0 },    #floor
        c => { pos => [ 7,  7 ],  archive => [ 3,  14 ], flag => 0 },    #upgrade
        d => { pos => [ 1,  4 ],  archive => [ 8,  15 ], flag => 0 },    #flag 3
        e => { pos => [ 9,  7 ],  archive => [ 1,  13 ], flag => 0 },    #flag 2
        f => { pos => [ 11, 11 ], archive => [ 11, 11 ], flag => 0 },    #wrench
    },
    touches => {
        archive => {
            a => { x => 0, y => 0 },
            c => { x => 7, y => 7 },
            d => { x => 1, y => 4, archive => ignore(), active => 1, flag => 3, id => 'flag_3', o => 0, solid => 0, type => 'flag' },
            e => { x => 9, y => 7, archive => ignore(), active => 1, flag => 2, id => 'flag_2', o => 0, solid => 0, type => 'flag' }, } } );

touches(
    scenario => "Flags",
    register => 3,
    bots     => {
        a => { pos => [ 7, 1 ], archive => [ 8, 15 ], flag => 0 },    #flag 1
        b => { pos => [ 9, 7 ], archive => [ 1, 13 ], flag => 0 },    #flag 2
        c => { pos => [ 1, 4 ], archive => [ 8, 15 ], flag => 2 },    #flag 3
    },
    state   => 'GAME OVER',
    touches => {
        archive => {
            a => { x => 7, y => 1, archive => ignore(), active => 1, flag => 1, id => 'flag_1', o => 0, solid => 0, type => 'flag' },
            b => { x => 9, y => 7, archive => ignore(), active => 1, flag => 2, id => 'flag_2', o => 0, solid => 0, type => 'flag' },
            c => { x => 1, y => 4, archive => ignore(), active => 1, flag => 3, id => 'flag_3', o => 0, solid => 0, type => 'flag' } },
        flag => { a => 1, c => 3 } } );

sub touches {
    my (%a) = @_;
    subtest $a{scenario} => sub {
        local $Test::Builder::Level = $Test::Builder::Level - 1;
        my $rally = Gamed::Test::Player->new('a')->create( 'RoboRally', 'test', { course => 'risky_exchange' } );
        my ( %pieces, @bots );
        my $id = 0;
        @bots = keys %{ $rally->{public}{bots} };
        while (my ($k, $v) = each %{$rally->{public}{course}{pieces}}) {
            delete $rally->{public}{course}{pieces}{$k} if $v->{type} eq 'bot';
        }
        while ( my ( $k, $v ) = each( %{ $a{bots} } ) ) {
            my $bot = shift @bots;
            my $piece = bot( $k, $v->{pos}[0], $v->{pos}[1], N, { archive => $v->{archive} });
            $rally->{public}{course}{pieces}{$k} = $piece;
            $rally->{players}{$k} ||= {};
            $rally->{players}{$k}{bot} = $piece;
            $piece->{flag} = $v->{flag};
            $piece->{active} = 1;
            $id++;
        }
        $rally->{states}{EXECUTING}{register} = $a{register};
        $rally->{states}{EXECUTING}->do_touches;
        if ( defined $a{touches} ) {
            my $msg = $rally->{players}{0}{client}{sock}{packets}[0];
            $a{touches}{cmd}   = 'execute';
            $a{touches}{phase} = 'touches';
            broadcast( $rally, $a{touches} );
            if ( defined $a{touches}{archive} ) {
                while ( my ( $bot, $pos ) = each %{ $a{touches}{archive} } ) {
                    my $piece = $rally->{public}{course}{pieces}{$bot};
                    is_deeply(
                        { x => $piece->{archive}{loc}{x}, y => $piece->{archive}{loc}{y} },
                        { x => $pos->{x},     y => $pos->{y} },
                        "$bot archive moved"
                    );
                }
            }
        }
        else {
            is( $rally->{players}{0}{sock}{packets}, undef );
        }
        delete $Gamed::instance{test};
        done_testing();
      }
}

done_testing();
