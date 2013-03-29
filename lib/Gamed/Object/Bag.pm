package Gamed::Object::Bag;

use overload '""' => \&to_string, '-' => \&difference, '+=' => \&plus_equals, eq => \&equal, ne => \&not_equal;

sub new {
    my $self = bless {}, shift;
    $self->add(@_);
    return $self;
}

sub add {
    my $self = shift;
    for my $v (@_) {
		next unless defined $v;
        my $ref = ref $v;
        if ( !$ref ) {
            $self->{$v}++;
        }
        elsif ( $ref eq 'ARRAY' ) {
            $self->{$_}++ for @$v;
        }
        elsif ( $ref eq 'Gamed::Object::Bag' ) {
            while ( my ( $k, $d ) = each %$v ) {
                $self->{$k} += $d;
            }
        }
    }
}

sub remove {
    my $self = shift;
    for my $v (@_) {
		next unless defined $v;
        my $ref = ref $v;
        if ( !$ref ) {
            die "No element '$v' exists in bag\n" unless exists $self->{$v};
            $self->{$v}--;
            delete $self->{$v} unless $self->{$v};
        }
        elsif ( $ref eq 'ARRAY' ) {
            $self->remove($_) for @$v;
        }
        elsif ( $ref eq 'Gamed::Object::Bag' ) {
            while ( my ( $k, $d ) = each %$v ) {
                $self->{$k} -= $d;
                die "No element '$k' exists in bag\n" if $self->{$k} < 0;
                delete $self->{$k} unless $self->{$k};
            }
        }
    }
}

sub plus_equals {
    my ( $a, $b ) = @_;
    my $c = Gamed::Object::Bag->new;
    $c->add($a);
    $c->add($b);
    return $c;
}

sub equal {
    my ( $a, $b ) = @_;
    return 0 if ref($a) ne ref($b);
    return 0 if scalar( keys(%$a) ) != scalar( keys(%$b) );
    while ( my ( $k, $v ) = each %$a ) {
        return 0 if $b->{$k} != $v;
    }
    return 1;
}

sub not_equal {
    return !$_[0]->equal( $_[1] );
}

sub difference {
    my ( $self, $other ) = @_;
    my $result = Gamed::Object::Bag->new;
    while ( my ( $k, $v ) = each %$self ) {
        my $o_v = $other->{$k} || 0;
        $result->{$k} = $v - $o_v if $o_v < $v;
    }
    return $result;
}

sub subset {
    my ( $self, $superset ) = @_;
    while ( my ( $k, $v ) = each %$self ) {
        return 0 unless defined $superset->{$k} && $superset->{$k} >= $v;
    }
    return 1;
}

sub contains {
	my ($self, $e) = @_;
	return exists $self->{$e};
}

sub values {
    my $self = shift;
    my @values;
    while ( my ( $k, $v ) = each %$self ) {
        push( @values, $k ) for 1 .. $v;
    }
	return @values;
}

sub to_string {
	return join(' ', sort(shift->values));
}

1;
