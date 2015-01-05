use strict;
use warnings;

use Test::More;
use Gamed;
use Gamed::Test;
use Data::Dumper;
use Gamed::Game::RoboRally;
use t::RoboRally;

touches(
    scenario => "Nothing",
    register => 1,
    bots     => { a => { pos => [ 5, 14 ], damage => 0, archive => [ 5, 15 ] } },
    messages => [] );

touches(
    scenario => "Move archives",
    register => 1,
    bots     => {
        a => { pos => [ 0,  0 ],  archive => [ 5,  15 ], damage => 0, flag => 0 },    #wrench
        b => { pos => [ 5,  5 ],  archive => [ 6,  15 ], damage => 0, flag => 0 },    #floor
        c => { pos => [ 7,  7 ],  archive => [ 3,  14 ], damage => 0, flag => 0 },    #upgrade
        d => { pos => [ 1,  4 ],  archive => [ 8,  15 ], damage => 0, flag => 0 },    #flag 3
        e => { pos => [ 9,  7 ],  archive => [ 1,  13 ], damage => 0, flag => 0 },    #flag 2
        f => { pos => [ 11, 11 ], archive => [ 11, 11 ], damage => 0, flag => 0 },    #wrench
    },
    touches => {
        archive => {
            a => { x => 0, y => 0 },
            c => { x => 7, y => 7 },
            d => { x => 1, y => 4 },
            e => { x => 9, y => 7 } } } );

touches(
    scenario => "Repair & Options",
    register => 5,
    bots     => {
        a => { pos => [ 0,  0 ],  archive => [ 5,  15 ], damage => 1, flag => 0 },    #wrench
        b => { pos => [ 5,  5 ],  archive => [ 6,  15 ], damage => 2, flag => 0 },    #floor
        c => { pos => [ 7,  7 ],  archive => [ 3,  14 ], damage => 2, flag => 0 },    #upgrade
        d => { pos => [ 1,  4 ],  archive => [ 8,  15 ], damage => 2, flag => 0 },    #flag 3
        e => { pos => [ 9,  7 ],  archive => [ 1,  13 ], damage => 0, flag => 0 },    #flag 2
        f => { pos => [ 11, 11 ], archive => [ 11, 11 ], damage => 2, flag => 0 },    #wrench
    },
    touches => {
        archive => {
            a => { x => 0, y => 0 },
            c => { x => 7, y => 7 },
            d => { x => 1, y => 4 },
            e => { x => 9, y => 7 } },
        repair  => { a => 0, c => 1, d => 1, f => 1 },
        options => { c => ['Brakes'] } } );

touches(
    scenario => "Flags",
    register => 3,
    bots     => {
        a => { pos => [ 7, 1 ], archive => [ 8, 15 ], damage => 0, flag => 0 },    #flag 1
        b => { pos => [ 9, 7 ], archive => [ 1, 13 ], damage => 0, flag => 0 },    #flag 2
        c => { pos => [ 1, 4 ], archive => [ 8, 15 ], damage => 0, flag => 2 },    #flag 3
    },
    state   => 'GAME OVER',
    touches => {
        archive => { a => { x => 7, y => 1 }, b => { x => 9, y => 7 }, c => { x => 1, y => 4 } },
        flag => { a => 1, c => 3 } } );

sub touches {
    my (%a) = @_;
    subtest $a{scenario} => sub {
        my $rally = Gamed::Test::Player->new('1')->create( 'RoboRally', 'test', { course => 'risky_exchange' } );
		$rally->{option_cards} = bless { cards => ['Brakes'] }, 'Gamed::Object::Deck';
		while( my ($k, $v) = each %{$rally->{players}}) {
			$v->{public}{bot} = 'a';
			$v->{public}{flag} = 0;
			$v->{public}{damage} = 0;
			$rally->{public}{bots}{a}{player} = $k;
		}

		for my $b (qw/b c d e f/) {
			$rally->{players}{$b}{public}{bot} = $b;
			$rally->{players}{$b}{public}{flag} = 0;
			$rally->{players}{$b}{public}{damage} = 0;
			$rally->{public}{bots}{$b}{player} = $b;
		}

        my ( %pieces, @bots );
        while ( my ( $k, $v ) = each( %{ $a{bots} } ) ) {
			my $player = $rally->{players}{$rally->{public}{bots}{$k}{player}};
			$player->{public}{damage} = $v->{damage};
			$player->{public}{flag} = $v->{flag};
            $rally->{public}{course}{pieces}{$k} = (bot($k, $v->{pos}[0], $v->{pos}[1], N))[1];
            $rally->{public}{course}{pieces}{"$k\_archive"} = (archive($k, $v->{archive}[0], $v->{archive}[1]))[1];
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
                    is_deeply( { x => $archive->x, y => $archive->y }, { x => $pos->{x}, y => $pos->{y} }, "$bot archive moved" );
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
