package Gamed::Game::RoboRally::Course;

use strict;
use warnings;
use JSON::Any;
use File::Slurp;
use File::Spec::Functions 'catdir';

my $json = JSON::Any->new;

sub new {
    my ($pkg, $name) = @_;
    my $text = read_file(
        catdir( $Gamed::public, "g", "RoboRally", "courses", "$name.json" ) );
    die "No course named " . $name . " known" unless $text;
	my $course = $json->decode($text);
	my %self = ( course => $course );
	for my $y ( 0 .. $#{$course->{tiles}} ) {
		my $row = $course->{tiles}[$y];
		for my $x ( 0 .. $#$row ) {
			my $tile = $row->[$x];
			if ($tile->{t} && $tile->{t} =~ /^[1-8]$/) {
				$self{start}{$tile->{t}} = [$x,$y];
			}
		}
	}
    bless \%self, $pkg;
}

sub add_bot {
	my ($self, $bot, $num) = @_;
	my $loc = $self->{start}{$num};
	$self->{course}{pieces}{$bot} = {x=>$loc->[0], y => $loc->[1]};
	$self->{course}{pieces}{"$bot\_archive"} = {x=>$loc->[0], y => $loc->[1]};
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
	my $self = shift;
}

sub do_express_conveyors {
	my $self = shift;
}

sub do_conveyors {
	my $self = shift;
}

sub do_pushers {
	my $self = shift;
}

sub do_gears {
	my $self = shift;
}

sub do_lasers {
	my $self = shift;
}

sub do_touches {
	my $self = shift;
}

sub TO_JSON {
	return $_[0]->{course};
}

1;
