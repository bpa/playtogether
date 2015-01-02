package t::RoboRally;

use strict;
use warnings;
use Exporter 'import';
our @EXPORT = qw/N E S W bot archive flag/;
use Gamed::Game::RoboRally::Course;

use constant N => 0;
use constant E => 1;
use constant S => 2;
use constant W => 3;

sub bot {
    my ( $id, $x, $y, $o ) = @_;
    return $id => Gamed::Game::RoboRally::Course::Piece( $id, 'bot', $x, $y, $o, 1, 0 );
}

sub archive {
    my ( $id, $x, $y ) = @_;
    return "$id\_archive" => Gamed::Game::RoboRally::Course::Piece( "$id\_archive", 'archive', $x, $y, 0, 0, 0 );
}

sub flag {
    my ( $id, $x, $y ) = @_;
    return "flag_$id" => Gamed::Game::RoboRally::Course::Piece( "flag_$id", 'flag', $x, $y, 0, 0, $id );
}

1;
