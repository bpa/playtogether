package Gamed::Game::RoboRally::Course;

use strict;
use warnings;
use JSON::Any;
use File::Slurp;
use File::Spec::Functions 'catdir';
use List::Util 'min';

my $json       = JSON::Any->new;
my %rotations  = ( r => 1, u => 2, l => 3 );
my @movement   = ( -1, 1, 1, -1 );
my @walls      = ( 1, 2, 4, 8 );

sub new {
    my ( $pkg, $name ) = @_;
    my $text = read_file( catdir( $Gamed::public, "g", "RoboRally", "courses", "$name.json" ) );
    die "No course named " . $name . " known" unless $text;
    my $course = $json->decode($text);
    my %self = ( course => $course );
    for my $y ( 0 .. $#{ $course->{tiles} } ) {
        my $row = $course->{tiles}[$y];
        for my $x ( 0 .. $#$row ) {
            my $tile = $row->[$x];
			$tile->{w} ||= 0;
            if ( $tile->{t} && $tile->{t} =~ /^[1-8]$/o ) {
                $self{start}{ $tile->{t} } = [ $x, $y ];
            }
        }
    }
	$self{tiles} = $course->{tiles};
	$self{w} = $course->{width};
	$self{h} = $course->{height};
    bless \%self, $pkg;
}

sub add_bot {
    my ( $self, $bot, $num ) = @_;
    my $loc = $self->{start}{$num};
    $self->{course}{pieces}{$bot} = { x => $loc->[0], y => $loc->[1], o => 0, solid => 1, id => $bot };
    $self->{course}{pieces}{"$bot\_archive"} = { x => $loc->[0], y => $loc->[1] };
}

sub execute {
    my $self = shift;
    $self->do_movement;
    $self->do_express_conveyors;
    $self->do_conveyors;
    $self->do_pushers;
    $self->do_gears;
    $self->do_lasers;
    $self->do_touches;
}

sub pieces { return $_[0]->{course}{pieces} }

sub firstind(&@) {
	my $f = \&{shift @_};
	for my $ind ( 0 .. $#_ ) {
		local $_ = $_[$ind];
		return $ind if $f->();
	}
	return -1;
}

sub do_movement {
    my ( $self, $register, $cards ) = @_;
    my @moves;
    for my $c (@$cards) {
        my ( $action, $priority ) = $c->[1][0] =~ /^(.)(\d+)$/o;
        push @moves, [ $c->[0], $priority, $action ];
    }
    @moves = map { $self->do_move( $register, @$_ ) } sort { $b->[1] <=> $a->[1] } @moves;
    return \@moves;
}

sub do_move {
    my ( $self, $register, $id, $priority, $move, $optional ) = @_;
    my $piece = $self->{pieces}{$id};
    if ( $move =~ /[rlu]/o ) {
        $piece->{o} = ( $piece->{o} + $rotations{$move} ) % 4;
        return [ { piece => $id, rotate => $move } ];
    }

    my $dir = $piece->{o};
    if ( $move eq 'b' ) {
        $dir  = ( $dir + 2 ) % 4;
        $move = 1;
    }
	my $d = $movement[$dir];
	my ($xy, $z) = $dir % 2 == 0 ? qw/y x/ : qw/x y/;

	my @actions;
	my @pieces = grep { $_->{$z} == $piece->{$z} } values %{ $self->{pieces} };
	my $loc = $piece->{$xy};

	while ($move) {
		my $ind = firstind { $_->{$xy} == $loc } @pieces;
		$loc += $d;
		if ($ind == -1) {
			$move--;
			next;
		}
		$piece = splice @pieces, $ind, 1;
		$move = $self->max_movement($piece->{x}, $piece->{y}, $move, $dir, \@pieces);
		if ($move) {
			$piece->{$xy} += $d * $move;
			my %action = ( piece => $piece->{id}, move => $move, dir => $dir );
			my $tile = $self->{tiles}[$piece->{y}][$piece->{x}];
			if ($piece->{x} < 0 || $piece->{y} < 0 || $piece->{x} >= $self->{w} || $piece->{y} >= $self->{h}
				|| ($tile->{t} && $tile->{t} eq 'pit')) {
				delete $self->{pieces}{$piece->{id}};
				$action{die} = 'fall';
			}
			push @actions, \%action;
		}
	}

	return @actions ? \@actions : ();
}

sub max_movement {
	my ($self, $x, $y, $move, $dir, $pieces, $idx) = @_;
	my $front = $walls[$dir];
	my $back = $walls[($dir + 2) % 4];
	my @d = (0, 0);
	$d[$dir % 2] = $movement[$dir];
	my $tile = $self->{tiles}[$y][$x];
	my ($wall, $pit) = (0, 0);
	while ($wall < $move || $pit < $move) {
		return $wall if $tile->{w} & $front;
		$y += $d[0];
		$x += $d[1];
		if ($x < 0 || $y < 0 || $x >= $self->{w} || $y >= $self->{h}) {
			return min ++$pit, $move;
		}
		$tile = $self->{tiles}[$y][$x];
		return $wall if $tile->{w} & $back;
		$pit++;
		$wall++ unless grep { $_->{x} == $x && $_->{y} == $y } @$pieces;
		return min $move, $pit unless $tile;
		return min $move, $pit if $tile->{t} && $tile->{t} eq "pit";
	}
	return $move;
}

sub do_express_conveyors {
    my ( $self, $register ) = @_;
    return $self->move_conveyors('conveyor2');
}

sub do_conveyors {
    my ( $self, $register ) = @_;
    return $self->move_conveyors('conveyor');;
}

sub move_conveyors {
	my ($self, $type) = @_;
	my (@new, %actions, @replace);
	for my $p ( values %{ $self->{pieces} } ) {
		next if $p->{archive};
		my $tile = $self->{tiles}[$p->{y}][$p->{x}];
		my $dir = $tile->{o} || 0;
		my $x = $p->{x};
		my $y = $p->{y};
		if ($tile->{t} && $tile->{t} =~ $type) {
			next if $tile->{w} & $walls[$dir];
			my @d = (0, 0);
			$d[$dir % 2] = $movement[$dir];
			$y += $d[0];
			$x += $d[1];
			if ($x < 0 || $y < 0 || $x >= $self->{w} || $y >= $self->{h}) {
				$actions{$p->{id}} = { piece => $p->{id}, move => 1, dir => $dir, die => 'fall', x => $x, y => $y };
				next;
			}
			$tile = $self->{tiles}[$y][$x];
			my $next_dir = $tile->{o} || 0;
			next if $tile->{t} && $tile->{t} =~ $type && $next_dir == ($dir + 2) % 4;
			next if $tile->{w} & $walls[($dir + 2) % 4];
			if ($tile->{t} && $tile->{t} eq "pit") {
				$actions{$p->{id}} = { piece => $p->{id}, move => 1, dir => $dir, die => 'fall', x => $x, y => $y };
				next;
			}
		}
		else {
			$new[$x][$y] ||= $p;
		}
		if ($new[$x][$y]) {
			my $o = $p;
			my $r = $new[$x][$y];
			while ($r) {
				delete $actions{$r->{id}};
				last if $o->{id} eq $r->{id};
				$o = $r;
				$r = $new[$o->{x}][$o->{y}];
			}
			next;
		}
		$actions{$p->{id}} = { piece => $p->{id}, move => 1, dir => $dir, x => $x, y => $y };
		$new[$x][$y] = $p;
	}
	for my $p ( values %actions ) {
		my $piece = $self->{pieces}{$p->{piece}};
		$piece->{x} = delete $p->{x};
		$piece->{y} = delete $p->{y};
	}
	return %actions ? [ values %actions ] : ();
}

sub do_pushers {
    my ( $self, $register ) = @_;
    return;
}

sub do_gears {
    my ( $self, $register ) = @_;
    return;
}

sub do_lasers {
    my ( $self, $register ) = @_;
    return;
}

sub TO_JSON {
    return $_[0]->{course};
}

1;
