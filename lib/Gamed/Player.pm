package Gamed::Player;

use JSON::Any;

my $json = JSON::Any->new;

sub new {
	my $pkg = shift;
	bless $_[0], $pkg;
}

sub send {
	shift->{sock}->send($json->to_json($_[0]));
}

1;
