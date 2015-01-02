use strict;
use warnings;
use Test::More;
use Gamed;
use Gamed::Test;
use Data::Dumper;
use t::RoboRally;

my $course = Gamed::Game::RoboRally::Course->new('risky_exchange');

gears(
    scenario => "Spin away",
    before   => {
		bot('a', 8,  8,  E),
		bot('b', 9,  9,  S),
		bot('c', 10, 10, W), },
    actions => [ { piece => 'a', rotate => 'r', o => S }, { piece => 'c', rotate => 'l', o => S } ],
    final   => {
		bot('a', 8,  8,  S),
		bot('b', 9,  9,  S),
		bot('c', 10, 10, S), } );

sub gears {
    my (%a) = @_;
    subtest $a{scenario} => sub {
        my ( %pieces, @bots );
        $course->{pieces} = $a{before};
        my $actions = $course->do_gears( $a{register} );
        @{ $actions->[0] } = sort { $a->{piece} cmp $b->{piece} } @{ $actions->[0] } if $actions->[0];
        is_deeply( $actions, [ $a{actions} ] );
        while ( my ( $piece, $data ) = each %{ $a{final} } ) {
            is_deeply( $course->{pieces}{$piece}, $data, "$piece final position" );
        }
        done_testing();
      }
}

done_testing();
