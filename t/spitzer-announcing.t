use strict;
use warnings;

use Test::More;
use Test::Deep;
use Gamed;
use Gamed::Test;
use Gamed::Object;
use Data::Dumper;

my ( $spitzer, $n, $e, $s, $w ) = game( [qw/n e s w/], { game => 'Spitzer' } );

for my $p ($n, $e, $s, $w) {
	for my $z ('zola', 'zola schneider', 'zola schneider schwartz') {
		accepted( $p, announcement => $z, name => "Anyone can call $z", type => $z, team => [$p->{in_game_id}], caller => $p->{in_game_id} );
	}
}

$spitzer->{players}{n}{private}{cards} = bag(qw/QC AC 7D 10C 9D/);
$spitzer->{players}{e}{private}{cards} = bag(qw/QS JC 8D 11C 10D/);
$spitzer->{players}{s}{private}{cards} = bag(qw/AD KC 7D 10C 9D/);
$spitzer->{players}{w}{private}{cards} = bag(qw/AS 7C 7D 10C 9D/);

accepted( $n, announcement => 'none', name => 'Normal pass', state => 'Announcing' );
accepted( $e, announcement => 'none', name => 'Normal pass', state => 'Announcing' );
accepted( $s, announcement => 'none', name => 'Normal pass', state => 'Announcing' );
accepted( $w, announcement => 'none', name => 'Normal pass', type => 'normal', team => ['n', 'e'] );
accepted( $e, announcement => 'schneider', name => 'Schneider', type => 'schneider', team => ['n', 'e'], rules => { allow_schneider => 1 } );
rejected( $e, announcement => 'schneider', name => 'Schneider banned', rules => { allow_schneider => 0 });
accepted( $s, announcement => 'schneider', name => 'Schneider no queens', type => 'schneider', team => ['s', 'w'], rules => { allow_schneider => 1} );
rejected( $n, announcement => 'call', call => 'AH', name => "Can't call if you don't have both queens" );

$spitzer->{players}{n}{private}{cards} = bag(qw/QC QS 7D 10C 9D/);
$spitzer->{players}{e}{private}{cards} = bag(qw/AC JC 8D 11C 10D/);

accepted( $w, announcement => 'none', name => 'Sneaker', type => 'sneaker', team => ['n'] );
accepted( $n, announcement => 'call', call => 'AC', name => 'Call for ace', type => 'call', team => ['n', 'e'] );
accepted( $n, announcement => 'schneider', name => 'Schneider solo', type => 'schneider', team => ['n'], rules => { allow_schneider => 1 } );
rejected( $w, announcement => 'call', call => 'AC', name => 'Must have both queens');
rejected( $n, announcement => 'call', call => 'AS', name => "Have fail clubs, can't call for spades with no fail");
rejected( $n, announcement => 'call', call => 'AD', name => "Can't call for trump ace");
rejected( $n, announcement => 'first', name => "Can't call for first winner without all fail aces");

$spitzer->{players}{n}{private}{cards} = bag(qw/QC QS 8D AC 9C AH 7H AS/);

accepted( $n, announcement => 'call', call => 'first', name => "Call for first", team => ['n'], type => 'call' );
rejected( $w, announcement => 'call', call => 'AC', name => "Have all the queens, can't call for one");

done_testing;

sub accepted {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $p, @args) = @_;
    setup( pass => 1, player => $p, @args);
}

sub rejected {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $p, @args ) = @_;
    setup( pass => 0, player => $p, state => 'Announcing', @args);
}

sub setup {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my %opts   = @_;
    my $player = delete $opts{player};
	$opts{caller} = $player->{in_game_id} if $opts{announcement} ne 'none';
	$opts{state} ||= 'PlayTricks';
    $spitzer->{states}{ANNOUNCING}{starting_player} = 3;
    $spitzer->{public}{rules} = $opts{rules} || {};
    $spitzer->change_state('ANNOUNCING');
    Gamed::States::after_star($spitzer);
    for my $p ( values %{ $spitzer->{players} } ) {
        splice( @{ $p->{client}{sock}{packets} }, 0, $#{ $p->{client}{sock}{packets} } );
    }

    broadcast( $spitzer, { cmd => 'announcing', player => 'n' } );
    for my $p ( $n, $e, $s, $w ) {
        if ( $p->{in_game_id} ne $player->{in_game_id} ) {
            $p->broadcast( { cmd => 'announce', announcement => 'none' }, { cmd => 'announcing', player => ignore() } );
        }
        else {
            last;
        }
    }

    $player->game( { cmd => 'announce', announcement => $opts{announcement}, call => $opts{call} } );
    if ( !$opts{pass} ) {
        $player->got_one( { cmd => 'error', reason => ignore() } );
        return;
    }

	if ($opts{type}) {
		broadcast( $spitzer, { cmd => 'announcement', announcement => $opts{announcement}, call => $opts{call}, caller => $opts{caller}, player => ignore() } );
		is ( $spitzer->{type}, $opts{type} );
	}
	else {
		broadcast( $spitzer, { cmd => 'announcing', player => ignore() } );
	}
    my $name = $opts{name};
    is( $spitzer->{state}{name}, $opts{state}, "$name - state" );
}
