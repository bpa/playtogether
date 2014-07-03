package Card;

use overload '""' => \&TO_JSON;
use overload 'eq' => \&is_eq;

my @order = qw/0 5 6 7 8 9 10 11 12 13 14 1/;
my %order;
for my $i ( 0 .. $#order ) {
    $order{ $order[$i] } = $i;
}

sub new {
    my ( $pkg, $c ) = @_;
    my ( $v, $s ) = $c =~ /(.*)(.)$/;
    bless { v => $v, s => $s, o => $order{$v} }, $pkg;
}

use Data::Dumper;
sub TO_JSON { $_[0]->{v} . $_[0]->{s} }
sub o       { $_[0]->{o} }
sub s       { $_[0]->{s} eq '_' ? $_[1] : $_[0]->{s} }

sub is_eq {
    my ( $a, $b ) = @_;
    return $a->{v} == $b->{v}
      && $a->{s} eq $b->{s};
}

1;
