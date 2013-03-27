use Test::More;
use Gamed::Util;

my $bag = bag(qw/a b c c d e/);
is (scalar(keys %$bag), 5, 'Bag has 5 keys');
is ($bag->{a}, 1);
is ($bag->{c}, 2);

ok(bag(qw/a b c/)->subset($bag), 'subset');
ok(!bag(qw/A b c/)->subset($bag), '!subset');
ok(!bag(qw/a b c c c/)->subset($bag), 'too many Cs');

done_testing;
