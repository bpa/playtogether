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
        Bot( 'a', 0, 0, N, { damage => 0 } ),
        Bot( 'b', 5, 5, N, { damage => 2 } ),
        Bot( 'c', 7, 7, N, { damage => 1, options => ['Brakes'] } ),
        Bot( 'd', 1, 4, N, { damage => 1 } ),
        Bot( 'e', 9, 7, N, { damage => 0 } ), },
    messages => [
        {   p    => 'all',
            recv => {
                cmd     => 'repairs',
                repairs => { a => 1, c => 1, d => 1 },
                pieces  => {
                    bot( 'a', 0, 0, N, { damage => 0 } ),
                    bot( 'b', 5, 5, N, { damage => 2 } ),
                    bot( 'c', 7, 7, N, { damage => 1, options => ['Brakes'] } ),
                    bot( 'd', 1, 4, N, { damage => 1 } ),
                    bot( 'e', 9, 7, N, { damage => 0 } ) },
                options => { c => ['Brakes'] } } },
        { p => 'all', recv => { cmd => 'programming', cards => ignore() } } ] );

cleanup(
    'Damage related cleanup',
    deaths => ['a'],
    before => {
        dead( 'a', 7, 9, 2, { registers => [ dmg('r90'), dmg('l60'), dmg('r70'), dmg('3840'), dmg('u20') ], damage => 10 } ),
        bot('f', 11, 11, N,    #wrench
            {   registers => [ 'r90', 'l60', dmg('r70'), dmg('3840'), dmg('u20') ],
                damage    => 7, } ), },
    after => {
        Dead( 'a', 7, 9, 2, { damage => 2 } ),
        Bot( 'f', 11, 11, N, { registers => [ undef, undef, undef, dmg('3840'), dmg('u20') ], damage => 6 } ) },
    messages => [
        { p => 'all', recv => { cmd => 'repairs', repairs => { f => 1 }, options => {}, pieces => ignore() } },
        { p => 'all', recv => { cmd => 'placing', bot     => 'a', available => ignore() } } ] );

cleanup(
    'Died by falling - placing order',
    deaths => [ 'c', 'b', 'a' ],
    before => { dead( 'a', 11, 11, 3), dead( 'b', 0, 0, 2 ), dead( 'c', 5, 15, 1 ) },
    after  => {
        Bot( 'a', 11, 11, E, { damage => 2, lives => 2, archive => [11, 11] } ),
        Bot( 'b', 0,  0,  E, { damage => 2, lives => 1, archive => [ 0,  0] } ),
        Bot( 'c', 5,  15, E, { damage => 2, lives => 0, archive => [ 5, 15] } ), },
    messages => [
        { p => 'all', recv => { cmd => 'repairs', repairs => {},  options   => {}, pieces => ignore() } },
        { p => 'all', recv => { cmd => 'placing', bot     => 'c', available => ignore() } },
        { p => 'b',   send => { cmd => 'place',   x       => 5,   y         => 15, o      => E } },
        { p => 'b',   recv => { cmd => 'error',   reason  => 'Not your turn' } },
        { p => 'c',   send => { cmd => 'place',   x       => 5,   y         => 15, o      => E } },
        { p => 'all', recv => { cmd => 'place', piece => ( bot( 'c', 5, 15, E, { damage => 2, lives => 0, archive => [5, 15] } ) )[1] }, msg => 'c placed' },
        { p => 'all', recv => { cmd => 'placing', bot => 'b', available => ignore() } },
        { p => 'c',   send => { cmd => 'place',   x   => 5,   y         => 15, o => E } },
        { p => 'c',   recv => { cmd => 'error', reason => 'Not your turn' } },
        { p => 'b',   send => { cmd => 'place', x      => 0, y => 0, o => E } },
        { p => 'all', recv => { cmd => 'place', piece  => ( bot( 'b', 0, 0, E, { damage => 2, lives => 1 } ) )[1] }, msg => 'b placed' },
        { p => 'all', recv => { cmd => 'placing', bot => 'a', available => ignore() } },
        { p => 'a',   send => { cmd => 'place',   x   => 11,  y         => 11, o => E } },
        { p => 'all', recv => { cmd => 'place',       piece => ( bot( 'a', 11, 11, E, { damage => 2, lives => 2, archive => [11,11] } ) )[1] }, msg => 'a placed' },
        { p => 'all', recv => { cmd => 'programming', cards => ignore() } } ] );

cleanup(
    'No lives left',
    deaths => [ 'a', 'b' ],
    before => { dead( 'a', 0, 0, 0 ), dead( 'b', 11, 11, 2 ) },
    after    => { Dead( 'a', 0, 0, 0 ), Bot( 'b', 11, 11, E, { damage => 2, lives => 1, archive => [ 11, 11 ] } ) },
    messages => [
        { p => 'all', recv => { cmd => 'repairs', repairs => {},  options   => {}, pieces => ignore() } },
        { p => 'all', recv => { cmd => 'placing', bot     => 'b', available => ignore() } },
        { p => 'a',   send => { cmd => 'place',   x       => 0,   y         => 0,  o      => E } },
        { p => 'a',   recv => { cmd => 'error',   reason  => 'Not your turn' } },
        { p => 'b',   send => { cmd => 'place',   x       => 11,  y         => 11, o      => E } },
        { p => 'all', recv => { cmd => 'place',       piece => ( bot( 'b', 11, 11, E, { damage => 2, lives => 1, archive => [ 11, 11 ] } ) )[1] }, msg => 'b placed' },
        { p => 'all', recv => { cmd => 'programming', cards => ignore() } } ] );

cleanup(
    'Cleanup registers',
    deaths => ['a'],
    before => {
        dead( 'a', 3, 14, 2, { registers => [ dmg('r90'), dmg('l60'), dmg('r70'), dmg('3840'), dmg('u20') ] } ),
        bot( 'b', 7, 7, S ),    #upgrade
        bot('c', 11, 11, N,     #wrench
            {   damage    => 7,
                registers => [ 'r90', 'l60', dmg('r70'), dmg('3840'), dmg('u20') ] } ) },
    after => {
        Bot( 'a', 3, 14, E, { damage  => 2, lives => 1, archive => [ 3, 14 ] } ),
        Bot( 'b', 7, 7,  S, { options => ['Brakes'] } ),
        Bot('c', 11, 11, N,
            {   damage    => 6,
                registers => [ undef, undef, undef, dmg('3840'), dmg('u20') ], } ) },
    messages => [
        {   p    => 'all',
            recv => {
                cmd     => 'repairs',
                repairs => { c => 1 },
                pieces  => {
                    dead( 'a', 3, 14, 2, { damage => 2 } ),
                    bot( 'b', 7, 7, S, { options => ['Brakes'] } ),
                    bot('c', 11, 11, N,
                        {   damage    => 6,
                            registers => [ undef, undef, undef, dmg('3840'), dmg('u20') ], } ), },
                options => { b => ['Brakes'] } },
            msg => 'Initial' },
        { p => 'all', recv => { cmd => 'placing', bot => 'a', available => ignore() }, msg => 'A placing' },
        { p => 'a',   send => { cmd => 'place',   x   => 3,   y         => 14,         o   => E } },
        {   p    => 'all',
            recv => { cmd => 'place', piece => ( bot( 'a', 3, 14, E, { damage => 2, lives => 1, archive => [ 3, 14 ] } ) )[1] },
            msg  => 'Placement broadcast' }, ] );

done_testing();

sub dmg {
    my $program = shift;
    return { damaged => 1, program => [$program] };
}

sub cleanup {
    my ( $scenario, %a ) = @_;
    subtest $scenario => sub {
        local $Test::Builder::Level = $Test::Builder::Level - 1;
        my $p1 = Gamed::Test::Player->new('a');
        my $rally = $p1->create( 'RoboRally', 'test', { course => 'risky_exchange' } );
        $rally->{public}{bots}{a} = {};
        $rally->{public}{course}->add_bot('a');
        $rally->{public}{course}->place( $rally->{public}{course}{pieces}{a}, 1 );
        my %player = ( a => $p1 );
        $p1->broadcast( { cmd => 'bot', 'bot' => 'a', player => 0 } );
        my $pos = 2;

        for my $p ( grep { $_ ne 'a' && !/_archive/ } keys %{ $a{before} } ) {
            my $p1 = Gamed::Test::Player->new($p);
            $player{$p} = $p1;
            $p1->join('test');
            $rally->{public}{bots}{$p} = {};
            $rally->{public}{course}->add_bot($p);
            $rally->{public}{course}->place( $rally->{public}{course}{pieces}{$p}, $pos++ );
            $rally->{public}{course}->move( $rally->{public}{course}{pieces}{$p}, $a{before}{$p}{x}, $a{before}{$p}{y} );
            $p1->broadcast( { cmd => 'bot', 'bot' => $p }, { cmd => 'bot', 'bot' => $p, player => ignore() } );
        }
        while ( my ( $k, $v ) = each %{ $a{before} } ) {
            my $bot = $rally->{public}{course}{pieces}{$k};
            while ( my ( $bk, $bv ) = each %$v ) {
                $bot->{$bk} = $bv;
            } }
        if ( defined $a{deaths} ) {
            $rally->{deaths} = [ map { $rally->{public}{course}{pieces}{$_} } @{ $a{deaths} } ];
        }
        else {
            $rally->{deaths} = [];
        }
        $rally->{option_cards} = bless { cards => ['Brakes'] }, 'Gamed::Object::Deck';
        $rally->{state} = undef;
        $rally->change_state('CLEANUP');
        $rally->handle( $p1, { cmd => 1 } );

        for my $msg ( @{ $a{messages} } ) {
            if ( $msg->{recv} ) {
                if ( $msg->{p} eq 'all' ) {
                    broadcast( $rally, $msg->{recv}, $msg->{msg} );
                }
                else {
                    $player{ $msg->{p} }->got_one( $msg->{recv}, $msg->{msg} );
                } }
            else {
                $player{ $msg->{p} }->handle( $msg->{send} );
            } }

        while ( my ( $id, $bot ) = each( %{ $a{after} } ) ) {
            my ( $ok, $stack ) = cmp_details( $rally->{public}{course}{pieces}{$id}, $bot );
            ok( $ok, $id );
            if ( !$ok ) {
                diag deep_diag($stack);
            } }

        delete $Gamed::instance{test};
        done_testing();
      } }
