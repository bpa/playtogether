package Gamed::Game::RoboRally::Course;

use strict;
use warnings;
use JSON::MaybeXS;
use File::Slurp;
use File::Spec::Functions 'catdir';
use List::Util 'min';
use Struct::Dumb;

struct Piece => [qw/id type x y o solid/];
*{Gamed::Game::RoboRally::Course::Piece::TO_JSON} = sub {
	my $p = shift;
	return { id => $p->[0], type => $p->[1], x => $p->[2], y => $p->[3], o => $p->[4], solid => $p->[5] };
};

struct Flag => [qw/id type x y o solid flag/];
*{Gamed::Game::RoboRally::Course::Flag::TO_JSON} = sub {
	my $p = shift;
	return { id => $p->[0], type => $p->[1], x => $p->[2], y => $p->[3], o => $p->[4], solid => $p->[5], flag => $p->[6] };
};

my $json              = JSON::MaybeXS->new;
my %rotations         = ( r => 1, u => 2, l => 3 );
my @rotations         = qw/_ r u l/;
my @movement          = ( -1, 1, 1, -1 );
my @walls             = ( 1, 2, 4, 8 );
my %conveyor_rotation = (
    'r' => [ 0, 1, 0, 0 ],
    'l' => [ 0, 0, 0, 3 ],
    '^' => [ 0, 1, 0, 3 ] );

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
            $tile->{o} ||= 0;
            if ( $tile->{t} && $tile->{t} =~ /^[1-8]$/o ) {
                $self{start}{ $tile->{t} } = [ $x, $y ];
            }
        }
    }

	for my $p (values $course->{pieces}) {
		if ($p->{type} eq 'flag') {
			$p = Flag($p->{id}, $p->{type}, $p->{x}, $p->{y}, $p->{o} || 0, 0, $p->{flag} || 0 );
		}
		else {
			$p = Piece($p->{id}, $p->{type}, $p->{x}, $p->{y}, $p->{o} || 0, $p->{solid} || 0);
		}
	}

    $self{tiles}  = $course->{tiles};
    $self{pieces} = $course->{pieces};
    $self{w}      = $course->{width};
    $self{h}      = $course->{height};
    bless \%self, $pkg;
}

sub add_bot {
    my ( $self, $bot, $num ) = @_;
    my $loc = $self->{start}{$num};
    $self->{course}{pieces}{$bot} = Piece($bot, 'bot', $loc->[0], $loc->[1], 0, 1);
    $self->{course}{pieces}{"$bot\_archive"} = Piece($bot, 'archive', $loc->[0], $loc->[1], 0, 0);
}

sub pieces { return $_[0]->{course}{pieces} }

sub firstind(&@) {
    my $f = \&{ shift @_ };
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
    return () unless $piece;
    $piece->o ||= 0;
    if ( $move =~ /[rlu]/o ) {
        $piece->o = ( $piece->o + $rotations{$move} ) % 4;
        return [ { piece => $id, rotate => $move } ];
    }

    my $dir = $piece->o;
    if ( $move eq 'b' ) {
        $dir  = ( $dir + 2 ) % 4;
        $move = 1;
    }
    my $d = $movement[$dir];
    my ( $xy, $z ) = $dir % 2 == 0 ? qw/y x/ : qw/x y/;

    my @actions;
    my @pieces = grep { $_->solid && $_->$z == $piece->$z } values %{ $self->{pieces} };
    my $loc = $piece->$xy;

    while ($move) {
        my $ind = firstind { $_->$xy == $loc } @pieces;
        $loc += $d;
        if ( $ind == -1 ) {
            $move--;
            next;
        }
        $piece = splice @pieces, $ind, 1;
        $move = $self->max_movement( $piece->x, $piece->y, $move, $dir, \@pieces );
        if ($move) {
            $piece->$xy += $d * $move;
            my %action = ( piece => $piece->id, move => $move, dir => $dir );
            my $tile = $self->{tiles}[ $piece->y ][ $piece->x ];
            if (   $piece->x < 0
                || $piece->y < 0
                || $piece->x >= $self->{w}
                || $piece->y >= $self->{h}
                || ( $tile->{t} && $tile->{t} eq 'pit' ) )
            {
                delete $self->{pieces}{ $piece->id };
                $action{die} = 'fall';
            }
            push @actions, \%action;
        }
    }

    return @actions ? \@actions : ();
}

sub max_movement {
    my ( $self, $x, $y, $move, $dir, $pieces ) = @_;
    my $front = $walls[$dir];
    my $back  = $walls[ ( $dir + 2 ) % 4 ];
    my @d     = ( 0, 0 );
    $d[ $dir % 2 ] = $movement[$dir];
    my $tile = $self->{tiles}[$y][$x];
    my ( $wall, $pit ) = ( 0, 0 );
    while ( $wall < $move || $pit < $move ) {
        return $wall if $tile->{w} & $front;
        $y += $d[0];
        $x += $d[1];
        if ( $x < 0 || $y < 0 || $x >= $self->{w} || $y >= $self->{h} ) {
            return min ++$pit, $move;
        }
        $tile = $self->{tiles}[$y][$x];
        return $wall if $tile->{w} & $back;
        $pit++;
        $wall++ unless grep { $_->x == $x && $_->y == $y } @$pieces;
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
    return $self->move_conveyors('conveyor');
}

sub move_conveyors {
    my ( $self, $type ) = @_;
    my ( @new, %actions, @replace );
    for my $p ( values %{ $self->{pieces} } ) {
        next if $p->type eq 'archive';
        my $tile = $self->{tiles}[ $p->y ][ $p->x ];
        my $dir  = $tile->{o};
        my $x    = $p->x;
        my $y    = $p->y;
        if ( $tile->{t} && $tile->{t} =~ $type ) {
            next if $tile->{w} & $walls[$dir];
            my @d = ( 0, 0 );
            $d[ $dir % 2 ] = $movement[$dir];
            $y += $d[0];
            $x += $d[1];
            if ( $x < 0 || $y < 0 || $x >= $self->{w} || $y >= $self->{h} ) {
                $actions{ $p->id } =
                  { piece => $p->id, move => 1, dir => $dir, die => 'fall', x => $x, y => $y };
                next;
            }
            $tile = $self->{tiles}[$y][$x];
            my $next_dir = $tile->{o};
            next if $tile->{t} && $tile->{t} =~ $type && $next_dir == ( $dir + 2 ) % 4;
            next if $tile->{w} & $walls[ ( $dir + 2 ) % 4 ];
            if ( $tile->{t} && $tile->{t} eq "pit" ) {
                $actions{ $p->id } =
                  { piece => $p->id, move => 1, dir => $dir, die => 'fall', x => $x, y => $y };
                next;
            }
        }
        else {
            next unless $p->solid;
            $new[$x][$y] ||= $p;
        }
        if ( $p->solid && $new[$x][$y] ) {
            my @replace = ( $p, $new[$x][$y] );
            while (@replace) {
                my $o = shift @replace;
                my $r = $new[ $o->x ][ $o->y ];
                delete $actions{ $o->id };
                $new[ $o->x ][ $o->y ] = $o;
                if ( $r && $r->id ne $o->id ) {
                    push @replace, $r;
                }
            }
            next;
        }
        $actions{ $p->id } = { piece => $p->id, move => 1, dir => $dir, x => $x, y => $y };
        if ( $tile->{t} ) {
            my ($r) = $tile->{t} =~ /conveyor2?([rl^])$/;
            my $table = $r ? $conveyor_rotation{$r} : undef;
            if ($table) {
                my $side = ( 4 + $tile->{o} - $dir ) % 4;
                $actions{ $p->id }{rotate} = $rotations[ $table->[$side] ] if $table->[$side];
                $actions{ $p->id }{o} = ( 4 + $p->o + $table->[$side] ) % 4;
            }
        }
        if ( $p->solid ) {
            $new[$x][$y] = $p;
        }
    }
    for my $p ( values %actions ) {
        my $piece = $self->{pieces}{ $p->{piece} };
        $piece->x = delete $p->{x};
        $piece->y = delete $p->{y};
        $piece->o = delete $p->{o} || $piece->o;
    }
    return [ %actions ? [ values %actions ] : () ];
}

sub do_pushers {
    my ( $self, $register ) = @_;
    return;
}

sub do_gears {
    my ( $self, $register ) = @_;
    my @actions;
    for my $p ( values %{ $self->{pieces} } ) {
        next unless $p->solid;
        my $tile = $self->{tiles}[ $p->y ][ $p->x ];
        next unless $tile->{t};
        my ($dir) = $tile->{t} =~ /^gear_([rl])/;
        next unless $dir;
        $p->o = ( $p->o + $rotations{$dir} ) % 4;
        push @actions, { piece => $p->id, rotate => $dir, o => $p->o };
    }
    return [ @actions ? \@actions : () ];
}

sub do_lasers {
    my ( $self, $register ) = @_;
    return [];
}

sub TO_JSON {
    return $_[0]->{course};
}

1;
