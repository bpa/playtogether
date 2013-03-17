package Gamed::Player;

use JSON;

my $json = JSON->new->convert_blessed;

sub new {
	my $pkg = shift;
	bless $_[0], $pkg;
}

sub send {
	shift->{sock}->send($json->encode($_[0]));
}

1;
