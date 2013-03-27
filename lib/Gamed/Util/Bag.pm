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

sub subset {
	my ($self, $superset) = @_;
	while (my ($k, $v) = each %$self) {
		return 0 unless defined $superset->{$k} && $superset->{$k} >= $v;
	}
	return 1;
}

1;
