package t::RoboRally;

use strict;
use warnings;
use Exporter 'import';
our @EXPORT = qw/N E S W bot archive flag dead/;
use Gamed::Game::RoboRally::Pieces;

sub bot {
    my ( $id, $x, $y, $o, $opts ) = @_;
    my $bot = Bot( $id, $x, $y, $o );
	$opts ||= {};
    $opts->{active} = 1 unless exists $opts->{active};
	while (my ($k, $v) = each(%$opts) ) {
		$bot->{$k} = $v;
	}
    return $id => $bot;
}

sub dead {
    my ( $id, $lives, $opts ) = @_;
	$opts ||= {};
	$opts->{active} = 0;
    $opts->{lives} = $lives || 2;
    return bot( $id, 0, 0, N, $opts );
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
