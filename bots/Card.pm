package Card;

use overload '""' => \&TO_JSON;
use overload 'eq' => \&is_eq;

sub new {
    my ( $pkg, $c ) = @_;
    my ( $v, $s ) = $c =~ /(.*)(.)$/;
    bless { str => $c, v => $v, s => $s }, $pkg;
}

sub TO_JSON { $_[0]->{str} }
sub o       { die ref( $_[0] ) . " does not implement o\n" }
sub v       { $_[0]->{v} }
sub s       { $_[0]->{s} }

sub is_eq {
    my ( $a, $b ) = @_;
    return $a->{str} eq $b->{str};
}

package RookCard;

our @ISA   = 'Card';
our @order = qw/0 5 6 7 8 9 10 11 12 13 14 1/;
our %order;
for my $i ( 0 .. $#order ) {
    $order{ $order[$i] } = $i;
}

sub o { $order{ $_[0]->{v} } }
sub s { $_[0]->{s} eq '_' ? $_[1] : $_[0]->{s} }

package SpitzerCard;

our @ISA   = 'Card';
our %order = (
    7    => 0,
    8    => 1,
    9    => 2,
    J    => 3,
    Q    => 4,
    K    => 5,
    10   => 6,
    A    => 7,
    JD   => 8,
    JH   => 9,
    JS   => 10,
    JC   => 11,
    QD   => 12,
    QH   => 13,
    QS   => 14,
    '7D' => 15,
    QC   => 16
);

sub o { $order{ $_[0]->{str} } || $order{ $_[0]->{v} } || 0; }

sub s {
        $_[0]->{v} eq 'Q' ? 'D'
      : $_[0]->{v} eq 'J' ? 'D'
      :                     $_[0]->{s};
}

package ReztipsCard;

our @ISA = 'Card';

sub o { $SpitzerCard::order{ $_[0]->{str} } || $SpitzerCard::order{ $_[0]->{v} } || 0; }

sub s {
    my ( $c, $lead ) = @_;
	my $lead_suit = $lead ? $lead->s : '';
    if ( $lead_suit ne 'D' && $lead_suit eq $c->{s} ) {
		return $c->{s};
    }
    else {
        return
            $_[0]->{v} eq 'Q' ? 'D'
          : $_[0]->{v} eq 'J' ? 'D'
          :                     $_[0]->{s};
    }
}

1;
