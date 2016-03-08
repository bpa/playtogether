use strict;
use warnings;
use Test::More;
use Test::Deep qw/cmp_details deep_diag ignore/;
use Gamed;
use Gamed::Test;
use Data::Dumper;
use Gamed::Game::RoboRally::Course;
use t::RoboRally;

cleanup(
    "Repair & Upgrade",
    before => {
        bot( 'a', 0, 0, N, { damage => 1 } ),    #wrench
        bot( 'b', 5, 5, N, { damage => 2 } ),    #floor
        bot( 'c', 7, 7, N, { damage => 2 } ),    #upgrade
        bot( 'd', 1, 4, N, { damage => 2 } ),    #flag 3
        bot( 'e', 9, 7, N, { damage => 0 } ),    #flag 2
    },
    after => {
        bot( 'a', 0, 0, N, { damage => 0 } ),
        bot( 'b', 5, 5, N, { damage => 2 } ),
        bot( 'c', 7, 7, N, { damage => 1, options => ['Brakes'] } ),
        bot( 'd', 1, 4, N, { damage => 1 } ),
        bot( 'e', 9, 7, N, { damage => 0 } ),
    },
    messages => [ {
            p    => 'all',
            recv => {
                cmd    => 'repairs',
                repair => { a => 1, c => 1, d => 1},
                pieces => {
                    bot( 'a', 0, 0, N, { damage => 0 } ),
                    bot( 'b', 5, 5, N, { damage => 2 } ),
                    bot( 'c', 7, 7, N, { damage => 1, options => ['Brakes'] } ),
                    bot( 'd', 1, 4, N, { damage => 1 } ),
                    bot( 'e', 9, 7, N, { damage => 0 } )
                },
                options => { c => ['Brakes'] } } } ] );

cleanup(
    'Damage related cleanup',
	deaths => [ 'a' ],
    before => {
        dead('a', 2, {
            registers => [ dmg('r90'), dmg('l60'), dmg('r70'), dmg('3840'), dmg('u20') ],
            damage    => 10,
        } ),
		archive('a', 7, 9),
        bot('f', 11, 11, N, {    #wrench
            registers => [ 'r90', 'l60', dmg('r70'), dmg('3840'), dmg('u20') ],
            damage    => 7,
        } ),
    },
    after     => {
        dead('a', 2, { damage => 2 }),
		archive('a', 7, 9),
        bot('f', 11, 11, N, {
            registers => [ undef, undef, undef, dmg('3840'), dmg('u20') ],
            damage    => 6,
            }),
	},
    messages => [
        { p => 'all', recv => { cmd => 'repairs', repair => { f => 1 }, options => { }, pieces => ignore() } },
        #{ p => 'all', recv => { cmd => 'placing', bot => 'a' } } ] );
        { p => 'all', recv => { cmd => 'place' } } ] );

cleanup(
    'Died by falling',
	deaths => [ 'c', 'b', 'a' ],
    before => {
        dead('a', 2),
        dead('b', 1),
        dead('c', 0),
    },
    after => {
        dead('a', 2, { damage => 2 }),
        dead('b', 1, { damage => 2 }),
        dead('c', 0),
	},
    messages => [
        { p => 'all', recv => { cmd => 'repairs', repair => {}, options => {}, pieces => ignore() } },
        { p => 'all', recv => { cmd => 'placing', bot => 'b' } },
      ]);

cleanup(
    'Cleanup registers',
    deaths => [ 'a' ],
    before => {
        dead('a', 2, {
                registers => [ dmg('r90'), dmg('l60'), dmg('r70'), dmg('3840'), dmg('u20') ],
                damage    => 10,
            }
        ),
        archive( 'a', 3, 14 ),
        bot( 'b', 7, 7, S ),    #upgrade
        bot('c', 11, 11, N,     #wrench
            {   damage    => 7,
                registers => [ 'r90', 'l60', dmg('r70'), dmg('3840'), dmg('u20') ] } )
    },
    after => {
        bot( 'a', 3, 14, N, { damage  => 2, lives => 2 } ),
        bot( 'b', 7, 7,  S, { options => ['Brakes'] } ),
        bot('c', 11, 11, N,
            {   damage    => 6,
                registers => [ undef, undef, undef, dmg('3840'), dmg('u20') ],
            } ) },
    messages => [ {
            p    => 'all',
            recv => {
                cmd    => 'repairs',
                pieces => {
                    bot( 'b', 7, 7, S, { options => ['Brakes'] } ),
                    bot('c', 11, 11, N,
                        {   damage    => 6,
                            registers => [ undef, undef, undef, dmg('3840'), dmg('u20') ],
                        } ),
                  },
                options => { b => ['Brakes'] }
            },
            msg => 'Initial'
        },
        { p => 'a',   recv => { cmd => 'place' }, msg => 'A told to place' },
        { p => 'a',   send => { cmd => 'place', x => 3, y => 14, o => E } },
        { p => 'all', recv => { cmd => 'place', piece => ( bot( 'a', 3, 14, E, { damage => 2, lives => 2 } ) )[0] }, msg => 'Placement broadcast' },
    ] );

cleanup(
    'Place bot on archive marker',
    deaths => [ 'a', 'e', 'f', 'g' ],
    before => {
        dead( 'a', 2 ),
        bot( 'b', 0, 4, E ),
        bot( 'c', 3, 4, W ),
        bot( 'd', 1, 7, N ),
        dead('e'),
        dead( 'f', 1 ),
        dead( 'g', 0 ),
        archive( 'a', 1,  4 ),
        archive( 'e', 0,  0 ),
        archive( 'f', 13, 11 ),
    },
    after => {
        bot( 'a', 1, 4, N ),
        bot( 'b', 0, 4, E ),
        bot( 'c', 3, 4, W ),
        bot( 'd', 1, 7, N ),
        bot( 'e', 0, 0, W ),
        bot( 'f', 13, 11, E, { damage => 2, lives => 1 } ),
        dead( 'g', 0 ),
    },
    messages => [
        { p => 'all', recv => { cmd => 'repairs' } },
        { p => 'a',   recv => { cmd => 'place' } },
        { p => 'a',   send => { cmd => 'place', x => 2, y => 4, o => E } },
        { p => 'a', recv => { cmd => 'error', reason => 'Invalid placement' }, msg => "Must place on archive" },
        { p => 'a', send => { cmd => 'place', x => 1, y => 4, o => W } },
        { p => 'a', recv => { cmd => 'error', reason => 'Invalid placement' }, msg => "Can't face bot next to you" },
        { p => 'a', send => { cmd => 'place', x => 1, y => 4, o => E } },
        { p => 'a', recv => { cmd => 'error', reason => 'Invalid placement' }, msg => "Can't face bot 2 tiles away" },
        { p => 'a', send => { cmd => 'place', x => 1, y => 4, o => S } },
        { p => 'a', recv => { cmd => 'error', reason => 'Invalid placement' }, msg => "Can't face bot 3 tiles away" },
        { p => 'a', send => { cmd => 'place', x => 1, y => 4, o => N } },
        { p => 'all', recv => { cmd => 'place', piece => ( bot( 'a', 1, 4, N, { damage => 2, lives => 2 } ) )[0] } },
        { p => 'e',   recv => { cmd => 'place' } },
        { p => 'e', send => { cmd => 'place', x => 0, y => 0, o => W } },
        { p => 'all', recv => { cmd => 'place', piece => ( bot( 'e', 0, 0, W, { damage => 2, lives => 2 } ) )[0] } },
        { p => 'f', send => { cmd => 'place', x => 13, y => 11, o => E } },
        { p => 'all', recv => { cmd => 'place', piece => ( bot( 'f', 13, 11, E, { damage => 2, lives => 1 } ) )[0] } },
    ], );

cleanup(
    'Place next to archive marker',
    deaths => [ 'a' ],
    before => { dead( 'a', 2 ), bot( 'b', 0, 0, E ), bot( 'c', 0, 2, W ), archive( 'a', 0, 0 ), },
    after  => { bot( 'a', 1, 0, { damage => 2, lives => 2 } ), bot( 'b', 0, 0, E ), bot( 'c', 0, 2, W ) },
    messages => [
        { p => 'all', recv => { cmd => 'repairs' } },
        { p => 'a',   recv => { cmd => 'place' } },
        { p => 'a',   send => { cmd => 'place', x => 0, y => 0, o => E } },
        { p => 'a', recv => { cmd => 'error', reason => 'Invalid placement' }, msg => "Can't place on occupied tile" },
        { p => 'a', send => { cmd => 'place', x => 0, y => 1, o => S } },
        { p => 'a', recv => { cmd => 'error', reason => 'Invalid placement' }, msg => "Can't face bot next to you" },
        { p => 'a', send => { cmd => 'place', x => 1, y => 0, o => E } },
        { p => 'all', recv => { cmd => 'place', piece => ( bot( 'a', 1, 0, E, { damage => 2, lives => 2 } ) )[0] } },
    ] );

cleanup(
    'Corner case with no placement options on or adjacent to archive marker',
    deaths => [ 'a' ],
    before => {
        dead('a'),
        bot( 'b', 0, 0, E ),
        bot( 'c', 0, 1, W ),
        bot( 'd', 1, 1, N ),
        bot( 'e', 1, 0, S ),
        archive( 'a', 0, 0 ),
    },
    after =>
      { bot( 'a', 0, 0, E ), bot( 'b', 0, 0, E ), bot( 'c', 0, 1, W ), bot( 'd', 1, 1, N ), bot( 'e', 1, 0, S ), },
    messages => [
        { p => 'all', recv => { cmd => 'repairs' } },
        { p => 'a',   recv => { cmd => 'place' } },
        { p => 'a',   send => { cmd => 'place', x => 2, y => 0, o => W } },
        { p => 'a', recv => { cmd => 'error', reason => 'Invalid placement' }, msg => "Facing bot" },
        { p => 'a', send => { cmd => 'place', x => 2, y => 0, o => E } },
        { p => 'all', recv => { cmd => 'place', piece => ( bot( 'a', 0, 0, E, { damage => 2, lives => 2 } ) )[0] } },
    ] );

done_testing();

sub dmg {
    my $program = shift;
    return { damaged => 1, program => [ $program ] };
}

sub cleanup {
    my ( $scenario, %a ) = @_;
    subtest $scenario => sub {
        local $Test::Builder::Level = $Test::Builder::Level - 1;
        my $p1 = Gamed::Test::Player->new('a');
        my $rally = $p1->create( 'RoboRally', 'test', { course => 'risky_exchange' } );
        $rally->{public}{bots}{a} = {};
        $rally->{public}{course}->add_bot('a');
        my %player = ( a => $p1 );
        $p1->broadcast( { cmd => 'bot', 'bot' => 'a', player => 0 } );
        for my $p ( grep { $_ ne 'a' && !/_archive/ } keys %{ $a{before} } ) {
            my $p1 = Gamed::Test::Player->new($p);
            $player{$p} = $p1;
            $p1->join('test');
            $rally->{public}{bots}{$p} = {};
            $rally->{public}{course}->add_bot($p);
            $p1->broadcast( { cmd => 'bot', 'bot' => $p }, { cmd => 'bot', 'bot' => $p, player => ignore() } );
        }
        while ( my ( $k, $v ) = each %{ $a{before} } ) {
            my $bot = $rally->{public}{course}{pieces}{$k};
            while ( my ( $bk, $bv ) = each %$v ) {
                $bot->{$bk} = $bv;
            }
            push @{$rally->{deaths}}, $bot if $bot->{type} eq 'bot' && !$bot->{active};
        }
        $rally->{option_cards} = bless { cards => ['Brakes'] }, 'Gamed::Object::Deck';
        $rally->{state} = undef;
        $rally->change_state('CLEANUP');
        $rally->handle( $p1, { cmd => 1 } );

        for my $msg ( @{ $a{messages} } ) {
            if ( $msg->{recv} ) {
                if ( $msg->{p} eq 'all' ) {
                   print Dumper $msg->{recv};
                    broadcast( $rally, $msg->{recv}, $msg->{msg} );
                }
                else {
                    $player{ $msg->{p} }->got_one( $msg->{recv}, $msg->{msg} );
                }
            }
            else {
                $player{ $msg->{p} }->handle( $msg->{send} );
            }
        }

        while ( my ( $id, $bot ) = each( %{ $a{after} } ) ) {
            my ($ok, $stack) = cmp_details( $rally->{public}{course}{pieces}{$id}, $bot);
            ok($ok, $id);
            if (!$ok) {
              diag deep_diag($stack);
            }
        }

        delete $Gamed::instance{test};
        done_testing();
      }
}
