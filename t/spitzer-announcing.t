use strict;
use warnings;

use Test::More;
use Gamed;
use Gamed::Test;
use Gamed::Object;
use Data::Dumper;

my ( $spitzer, $n, $e, $s, $w ) = game( [qw/n e s w/], { game => 'Spitzer' } );

$spitzer->{players}{n}{private}{cards} = bag(qw/QC AC 7D 10C 9D/);
$spitzer->{players}{e}{private}{cards} = bag(qw/QS JC 8D 11C 10D/);
$spitzer->{players}{s}{private}{cards} = bag(qw/AD KC 7D 10C 9D/);
$spitzer->{players}{w}{private}{cards} = bag(qw/AS 7C 7D 10C 9D/);

accepted( $n, announcement => 'none', name => 'Normal pass', state => 'Announcing' );
accepted( $e, announcement => 'none', name => 'Normal pass', state => 'Announcing' );
accepted( $s, announcement => 'none', name => 'Normal pass', state => 'Announcing' );
accepted( $w, announcement => 'none', name => 'Normal pass', type => 'normal', team => ['n', 'e'] );
rejected( $n, announcement => 'call', call => 'AH', name => "Can't call if you don't have both queens" );

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
	$opts{state} ||= 'PlayTricks';
    $spitzer->{states}{ANNOUNCING}{starting_player} = 3;
    $spitzer->change_state('ANNOUNCING');
    Gamed::States::after_star($spitzer);
    for my $p ( values %{ $spitzer->{players} } ) {
        splice( @{ $p->{client}{sock}{packets} }, 0, $#{ $p->{client}{sock}{packets} } );
    }

    broadcast( $spitzer, { cmd => 'announcing', player => 'n' } );
    for my $p ( $n, $e, $s, $w ) {
        if ( $p->{in_game_id} ne $player->{in_game_id} ) {
            $p->broadcast( { cmd => 'announce', announcement => 'none' }, { cmd => 'announcing' } );
        }
        else {
            last;
        }
    }

    $player->game( { cmd => 'announce', announcement => $opts{announcement}, call => $opts{call} } );
    if ( !$opts{pass} ) {
        $player->got_one( { cmd => 'error' } );
        return;
    }

	if ($opts{type}) {
		broadcast( $spitzer, { cmd => 'announcement', announcement => $opts{announcement}, call => $opts{call}, caller => $opts{caller} } );
		is ( $spitzer->{type}, $opts{type} );
	}
	else {
		broadcast( $spitzer, { cmd => 'announcing' } );
	}
    my $name = $opts{name};
    is( $spitzer->{state}{name}, $opts{state}, "$name - state" );
}
