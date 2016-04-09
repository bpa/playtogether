package Gamed::Game::RoboRally::Pieces;

use Exporter 'import';
our @EXPORT = qw/N E S W/;

use constant N => 0;
use constant E => 1;
use constant S => 2;
use constant W => 3;

package Gamed::Game::RoboRally::Piece;

sub new {
    my $pkg = shift;
    return bless {
        id     => $_[0],
        type   => $_[1],
        x      => $_[2],
        y      => $_[3],
        o      => $_[4],
        solid  => $_[5],
        active => 1
    }, $pkg;
}

sub TO_JSON {
    return { %{$_[0]} }
}

package Gamed::Game::RoboRally::Bot;

our @ISA = 'Gamed::Game::RoboRally::Piece';

sub new {
    my $pkg = shift;

	my @register;
	for ( 1 .. 9 ) {
		push @register, { damaged => 0, $_ <= 5 ? ( program => [] ) : () };
	}

    return bless {
        id        => $_[0],
        x         => $_[1],
        y         => $_[2],
        o         => $_[3],
        l         => 1,
        d         => 1,
        ap        => 0,
        type      => 'bot',
        active    => 0,
        flag      => 0,
        lives     => 3,
		damage    => 0,
        solid     => 1,
        archive   => { loc => { x => 0, y => 0 }, damage => 2 },
        options   => [],
        registers => \@register,
    }, $pkg;
}

package Gamed::Game::RoboRally::Flag;

our @ISA = 'Gamed::Game::RoboRally::Piece';

sub new {
    my $pkg = shift;
    return bless {
        id      => 'flag_' . $_[0],
        flag    => $_[0],
        x       => $_[1],
        y       => $_[2],
        o       => 0,
        type    => 'flag',
        solid   => 0,
        active  => 1,
        archive => { loc => { x => $_[1], y => $_[2] } },
    }, $pkg;
}

1;
