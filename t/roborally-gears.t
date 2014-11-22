use strict;
use warnings;
use Test::More;
use Gamed;
use Gamed::Test;
use Data::Dumper;
use Gamed::Game::RoboRally::Course;

my $course = Gamed::Game::RoboRally::Course->new('risky_exchange');

gears(
    scenario => "Spin away",
    before   => {
        a => { x => 8,  y => 8,  o => 1, solid => 1 },
        b => { x => 9,  y => 9,  o => 2, solid => 1 },
        c => { x => 10, y => 10, o => 3, solid => 1 },
    },
    actions => [ { piece => 'a', rotate => 'l' }, { piece => 'c', rotate => 'r' } ],
    final   => {
        a => { x => 8,  y => 8,  o => 0, solid => 1 },
        b => { x => 9,  y => 9,  o => 2, solid => 1 },
        c => { x => 10, y => 10, o => 0, solid => 1 },
    } );

sub gears {
    my (%a) = @_;
    subtest $a{scenario} => sub {
        my ( %pieces, @bots );
        while ( my ( $k, $v ) = each( %{ $a{before} } ) ) {
            $v->{id} = $k;
        }
        while ( my ( $k, $v ) = each( %{ $a{final} } ) ) {
            $v->{id} = $k;
        }
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
