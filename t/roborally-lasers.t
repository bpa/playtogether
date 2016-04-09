use strict;
use warnings;
use Test::More;
use Gamed;
use Gamed::Test;
use Data::Dumper;
use t::RoboRally;

my $course = Gamed::Game::RoboRally::Course->new('dizzy_dash');

SKIP: {
    skip "No tests written", 1;
    ok( 0, 'Tests written' );
}

sub laser {
    my (%a) = @_;
    subtest $a{scenario} => sub {
        my ( %pieces, @bots );
        $course->{pieces} = $a{before};
        my $actions = $course->do_gears( $a{register} );
        @$actions = sort { $a->{id} cmp $b->{id} } @$actions if $actions;
        is_deeply( $actions, $a{actions} );
        while ( my ( $piece, $data ) = each %{ $a{final} } ) {
            is_deeply( $course->{pieces}{$piece}, $data, "$piece final position" );
        }
        done_testing();
      }
}

done_testing();
