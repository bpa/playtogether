use Test::More;
use Gamed::Object;
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

my $b = bag(qw/a b/);
$b += $b;
is_deeply([sort $b->values], [qw/a a b b/], 'add');

$b->add(qw/c d/);
is_deeply([sort $b->values], [qw/a a b b c d/], 'add literal');

$b += [qw/e f/];
is_deeply([sort $b->values], [qw/a a b b c d e f/], 'add arrayref');

$b->remove('a');
is_deeply([sort $b->values], [qw/a b b c d e f/], 'remove scalar');

$b->remove([qw/d e f/]);
is_deeply([sort $b->values], [qw/a b b c/], 'remove arrayref');

$b->remove(bag(qw/a b/));
is_deeply([sort $b->values], [qw/b c/], 'remove bag');

done_testing;
