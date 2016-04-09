package t::RoboRally;

use strict;
use warnings;
use JSON::MaybeXS;
use Exporter 'import';
our @EXPORT = qw/N E S W piece bot Bot flag dead Dead/;
use Gamed::Game::RoboRally::Pieces;

my $json = JSON::MaybeXS->new(convert_blessed => 1);

sub bot {
    my ( $id, $x, $y, $o, $opts ) = @_;
    my $bot = Gamed::Game::RoboRally::Bot->new( $id, $x, $y, $o );
    apply_opts($bot, $opts);
    return $id => $json->decode($json->encode($bot));
}

sub Bot {
    my ( $id, $x, $y, $o, $opts ) = @_;
    my $bot = Gamed::Game::RoboRally::Bot->new( $id, $x, $y, $o );
    apply_opts($bot, $opts);
    return $id => $bot;
}

sub apply_opts {
    my ( $piece, $opts ) = @_;
	$opts ||= {};
    my $archive;
    if ($opts->{archive} && ref($opts->{archive}) eq 'ARRAY') {
        $archive = delete $opts->{archive};
        $piece->{archive}{loc}{x} = $archive->[0];
        $piece->{archive}{loc}{y} = $archive->[1];
    }
    my $registers = delete $opts->{registers};
    if ($registers) {
        for my $i ( 0 .. $#$registers ) {
            if ( ref( $registers->[$i] ) eq 'HASH' ) {
                $piece->{registers}[$i] = $registers->[$i];
            }
            elsif ( ref( $registers->[$i] ) eq 'ARRAY' ) {
                $piece->{registers}[$i]{program} = $registers->[$i];
            }
            elsif ( $registers->[$i] ) {
                $piece->{registers}[$i]{program} = [ $registers->[$i] ];
            }
        }
    }
    if ($opts->{damage}) {
        for my $i (9 - $opts->{damage} .. 8) {
            $piece->{registers}[$i]{damaged} = 1;
        }
    }
    $opts->{active} = 1 unless exists $opts->{active};
	while (my ($k, $v) = each(%$opts) ) {
		$piece->{$k} = $v;
	}
}

sub dead {
    my ( $id, $x, $y, $lives, $opts ) = @_;
	$opts ||= {};
    $opts->{archive} = [ $x, $y ];
	$opts->{active} = 0;
    $opts->{lives} = defined $lives ? $lives : 2;
    return bot( $id, 0, 0, N, $opts );
}

sub Dead {
    my ( $id, $x, $y, $lives, $opts ) = @_;
	$opts ||= {};
    $opts->{archive} = [ $x, $y ];
	$opts->{active} = 0;
    $opts->{lives} = defined $lives ? $lives : 2;
    return Bot( $id, 0, 0, N, $opts );
}

sub flag {
    my ( $id, $x, $y, $opts ) = @_;
    my $flag = Gamed::Game::RoboRally::Flag->new( $id, $x, $y );
    apply_opts($flag, $opts);
    return "flag_$id" => $json->decode($json->encode($flag));
}

sub piece {
    my ( $id, $type, $x, $y, $o, $solid, $active, $opts ) = @_;
    my $piece = Gamed::Game::RoboRally::Piece->new( $id, $type, $x, $y, $o, $solid, $active );
    apply_opts($piece, $opts);
    return $id => $json->decode($json->encode($piece));
}

1;
