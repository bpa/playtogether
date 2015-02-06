use strict;
use warnings;

use Test::More;
use Gamed;
use Gamed::Test;
use Data::Dumper;
use Gamed::Game::RoboRally;
use Gamed::Game::RoboRally::Pieces;

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
            d => { x => 1, y => 4 },
            e => { x => 9, y => 7 } } } );

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
        archive => { a => { x => 7, y => 1 }, b => { x => 9, y => 7 }, c => { x => 1, y => 4 } },
        flag => { a => 1, c => 3 } } );

sub touches {
    my (%a) = @_;
    subtest $a{scenario} => sub {
        my $rally = Gamed::Test::Player->new('a')->create( 'RoboRally', 'test', { course => 'risky_exchange' } );
        my ( %pieces, @bots );
        my $id = 0;
        @bots = keys $rally->{public}{bots};
        while (my ($k, $v) = each %{$rally->{public}{course}{pieces}}) {
            delete $rally->{public}{course}{pieces}{$k} if $v->{type} eq 'bot';
        }
        while ( my ( $k, $v ) = each( %{ $a{bots} } ) ) {
            my $bot = shift @bots;
            my $piece = Bot( $k, $v->{pos}[0], $v->{pos}[1], N );
            $rally->{public}{course}{pieces}{$k} = $piece;
            $rally->{players}{$k} ||= {};
            $rally->{players}{$k}{bot} = $piece;
            $piece->{flag} = $v->{flag};
            $piece->{active} = 1;
            $rally->{public}{course}{pieces}{"$k\_archive"} = Archive( $k, $v->{archive}[0], $v->{archive}[1] );
            $id++;
        }
        $rally->{states}{EXECUTING}{register} = $a{register};
        $rally->{states}{EXECUTING}->do_touches;
        if ( defined $a{touches} ) {
            my $msg = $rally->{players}{0}{client}{sock}{packets}[0];
            $a{touches}{cmd}   = 'execute';
            $a{touches}{phase} = 'touches';
            broadcast( $rally, { cmd => 'execute', phase => 'touches' } );
            is_deeply( $msg, $a{touches} );
            if ( defined $a{touches}{archive} ) {
                while ( my ( $bot, $pos ) = each %{ $a{touches}{archive} } ) {
                    my $archive = $rally->{public}{course}{pieces}{"$bot\_archive"};
                    is_deeply(
                        { x => $archive->{x}, y => $archive->{y} },
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
