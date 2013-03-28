package Gamed::Util::Bag;

use overload '-' => \&difference;

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

sub difference {
    my ($self, $other) = @_;
    my $result = Gamed::Util::Bag->new;
    while (my ($k, $v) = each %$self) {
        my $o_v = $other->{$k} || 0;
        $result->{$k} = $v - $o_v if $o_v < $v;
    }
    return $result;
}

sub subset {
	my ($self, $superset) = @_;
	while (my ($k, $v) = each %$self) {
		return 0 unless defined $superset->{$k} && $superset->{$k} >= $v;
	}
	return 1;
}

sub values {
    my $self = shift;
    my @values;
    while (my ($k, $v) = each %$self) {
        push(@values, $k) for 1 .. $v;
    }
    return @values;
}

1;
