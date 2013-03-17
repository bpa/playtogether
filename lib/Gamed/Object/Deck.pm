package Gamed::Object::Deck;

use List::Util;

sub new {
	my $self = bless {}, shift;
	$self->build(@_);
	return $self;
}

sub reset {
	my $self = shift;
	$self->{cards} = $self->generate_cards;
	return $self;
}

sub shuffle {
	my $self = shift;
	@{$self->{cards}} = List::Util::shuffle @{$self->{cards}};
}

sub deal {
	my ($self, $cards) = @_;
	$cards ||= 1;
	return splice(@{$self->{cards}}, 0, $cards);
}

1;
