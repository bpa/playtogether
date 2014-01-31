package Gamed::Game::SpeedRisk::Board;

use Moose;
use JSON::Any;
use File::Slurp;
use namespace::clean;

has 'variant' => ( is => 'ro', required => 1);
my $json = JSON::Any->new;

sub BUILD {
    my $self = shift;
	my $text = read_file("$Gamed::resources/" . $self->variant . "/board.json");
	die "No board named " . $self->variant . " known" unless $text;
	my $board = $json->decode($text);
	while (my ($k, $v) = each %$board) {
		$self->{$k} = $v;
	}
}

__PACKAGE__->meta->make_immutable;
