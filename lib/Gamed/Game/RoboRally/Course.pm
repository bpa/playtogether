package Gamed::Game::RoboRally::Course;

use strict;
use warnings;
use JSON::Any;
use File::Slurp;
use File::Spec::Functions 'catdir';

my $json       = JSON::Any->new;
my %rotations  = ( r => 1, u => 2, l => 3 );
my @movement   = ( [ 0, -1 ], [ 1, 0 ], [ 0, 1 ], [ -1, 0 ] );

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
            if ( $tile->{t} && $tile->{t} =~ /^[1-8]$/o ) {
                $self{start}{ $tile->{t} } = [ $x, $y ];
            }
        }
    }
    bless \%self, $pkg;
}

sub add_bot {
    my ( $self, $bot, $num ) = @_;
    my $loc = $self->{start}{$num};
    $self->{course}{pieces}{$bot} = { x => $loc->[0], y => $loc->[1], o => 'n', solid => 1 };
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
        my $dir = $directions{ $piece->{o} };
        $piece->{o} = $directions{ ( $dir + $rotations{$move} ) % 4 };
        return [ { piece => $id, rotate => $move } ];
    }

    my $dir = $directions{ $piece->{o} };

    if ( $move eq 'b' ) {
        $dir  = ( $dir + 2 ) % 4;
        $move = 1;
    }

    my $dx = $movement[$dir][0] * $move;
    my $dy = $movement[$dir][1] * $move;
    $piece->{x} += $dx;
    $piece->{y} += $dy;
    return [ { piece => $id, move => $move, dir => $directions{$dir} } ];
}

sub do_express_conveyors {
    my ( $self, $register ) = @_;
    return;
}

sub do_conveyors {
    my ( $self, $register ) = @_;
    return;
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
