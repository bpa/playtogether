package Gamed::Object::Deck::Rook;

use parent 'Gamed::Object::Deck';

sub build {
    my ( $self, $options ) = @_;
    $options ||= '';
    $self->{range} = $options eq 'partnership' ? [ 1, 5 .. 14 ] : [ 1 .. 14 ];
}

sub generate_cards {
    my $self = shift;
    my @cards;
    for my $suit ( 'B', 'G', 'R', 'Y' ) {
        for my $v ( @{ $self->{range} } ) {

            push @cards, Gamed::Object::Card::Rook->new( $v, $suit );
        }
    }
    push @cards, Gamed::Object::Card::Rook->new(0);
    return \@cards;
}

1;
