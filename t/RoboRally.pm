package t::RoboRally;

use strict;
use warnings;
use Exporter 'import';
our @EXPORT = qw/N E S W bot archive flag dead/;
use Gamed::Game::RoboRally::Pieces;

sub bot {
    my ( $id, $x, $y, $o ) = @_;
    my $bot = Bot( $id, $x, $y, $o );
    $bot->{active} = 1;
    return $id => $bot;
}

sub dead {
    my ( $id, $o, $lives ) = @_;
    my $bot = Bot( $id, 0, 0, $o );
    $bot->{active} = 0;
    $bot->{lives} = $lives || 3;
    return $id => $bot;
}

sub archive {
    my ( $id, $x, $y ) = @_;
    return "$id\_archive" => Archive( $id, $x, $y );
}

sub flag {
    my ( $id, $x, $y ) = @_;
    return "flag_$id" => Flag( $id, $x, $y );
}

1;
