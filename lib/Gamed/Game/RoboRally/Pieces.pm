package Gamed::Game::RoboRally::Pieces;

use Exporter 'import';
our @EXPORT = qw/Bot Archive Flag Piece N E S W/;

use constant N => 0;
use constant E => 1;
use constant S => 2;
use constant W => 3;

sub Piece {
    return {
        id     => $_[0],
        type   => $_[1],
        x      => $_[2],
        y      => $_[3],
        o      => $_[4],
        solid  => $_[5],
        active => 1
    };
}

sub Bot {
	my @register;
	for ( 1 .. 9 ) {
		push @register, { damaged => 0, $_ <= 5 ? ( program => [] ) : () };
	}

    return {
        id        => $_[0],
        x         => $_[1],
        y         => $_[2],
        o         => $_[3],
        type      => 'bot',
        active    => 0,
        flag      => 0,
        lives     => 3,
		damage    => 0,
        solid     => 1,
        options   => [],
        register  => \@register,
    };
}

sub Archive {
    return {
        id     => $_[0] . '_archive',
        x      => $_[1],
        y      => $_[2],
        o      => 0,
        type   => 'archive',
        solid  => 0,
        active => 1
    };
}

sub Flag {
    return {
        id     => 'flag_' . $_[0],
        flag   => $_[0],
        x      => $_[1],
        y      => $_[2],
        o      => 0,
        type   => 'flag',
        solid  => 0,
        active => 1
    };
}

1;
