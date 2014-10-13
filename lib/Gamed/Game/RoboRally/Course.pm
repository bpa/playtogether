package Gamed::Game::RoboRally::Course;

use JSON::Any;
use File::Slurp;
use File::Spec::Functions 'catdir';
use Data::Dumper;

my $json = JSON::Any->new;

sub new {
    my ($pkg, $name) = @_;
    my $text = read_file(
        catdir( $Gamed::public, "g", "RoboRally", "courses", "$name.json" ) );
    die "No course named " . $name . " known" unless $text;
	my $course = $json->decode($text);
    my $self = bless { course => $course }, $pkg;
	$self->check_tile_types;
	return $self;
}

sub check_tile_types {
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
