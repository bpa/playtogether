use strict;
use warnings;

use Test::More;
use Gamed;
use Gamed::Test;
use Gamed::Object;
use Data::Dumper;

my %hand = (
	n => bag(qw/QC AC 7D 10C 9D/),
	e => bag(qw/QS JC 8D 11C 10D/),
	s => bag(qw/AD KC 7D 10C 9D/),
	w => bag(qw/AS 7C 7D 10C 9D/),
);

accepted( 'n', 'none', '', 'Normal pass' );
rejected( 'n', 'call', 'AH', "Can't call if you don't have both queens");

done_testing;

sub rejected {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
}

sub accepted {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my %opts = @_;
    my $game = bless {
        states => {
            GAME_OVER => bless( { name => 'Game Over' }, 'Gamed::State' ),
        },
        state        => bless( { name => 'start' }, 'Gamed::State' ),
        seats        => [qw/n e s w/],
        type         => $opts{type},
        calling_team => $opts{calling_team},
        players      => {
            n => { private => { cards => $hand{n} } },
            e => { private => { cards => $hand{e} } },
            s => { private => { cards => $hand{s} } },
            w => { private => { cards => $hand{w} } },
        },
      },
      'Gamed::Game::Spitzer';

    $logic->on_round_end($game);
    Gamed::States::after_star($game);
    my $name = $opts{name};
    is( $game->{state}{name}, $opts{state}, "$name - state" );
}
