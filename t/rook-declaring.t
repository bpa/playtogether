use strict;
use warnings;

use Test::More;
use Gamed;
use Gamed::Test;
use Data::Dumper;

my ( $game, $n, $e, $s ) = game(
    'Test', 'test',
    [qw/n e/],
    {
        seats       => [qw/n e/],
        bidder      => 1,
        bid         => 135,
        nest        => cards(qw/1R 14R 13R 12R 11R/),
        state_table => { start => Gamed::Game::Rook::Declaring->new('end') } } );
$game->{seat}[1]{cards} = cards(qw/5G 6G 7G 8G 9G 5R 6R 7R 8R 9R/);

$n->game( { trump => 'R' }, { reason => 'Not your turn' } );

done_testing;

sub cards {
    my @hand;
    for (@_) {
        push @hand, Gamed::Object::Card::Rook->new(@_);
    }
    return \@hand;
}
