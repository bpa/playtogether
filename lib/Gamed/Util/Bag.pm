package Gamed::Util::Bag;

sub new {
	my $self = bless {}, shift;
	$self->add(@_);
	return $self;
}

sub add {
	my $self = shift;
	for (@_) {
		$self->{$_}++;
	}
}

1;
