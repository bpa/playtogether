use Test::More;
use Gamed::Util;
use strict;
use warnings;

my $bag = bag(qw/a b c c d e/);
is (scalar(keys %$bag), 5, 'Bag has 5 keys');
is ($bag->{a}, 1);
is ($bag->{c}, 2);

ok(bag(qw/a b c/)->subset($bag), 'subset');
ok(!bag(qw/A b c/)->subset($bag), '!subset');
ok(!bag(qw/a b c c c/)->subset($bag), 'too many Cs');

my @values = $bag->values;
is_deeply([sort @values], [qw/a b c c d e/], 'values');
my $diff = $bag - bag(qw/a c e/);
is_deeply([sort $diff->values], [qw/b c d/], 'subtract');

done_testing;
