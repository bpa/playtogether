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
    bless { course => $course }, $pkg;
}

sub TO_JSON {
	return $_[0]->{course};
}

1;
