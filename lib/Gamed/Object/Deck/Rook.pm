package Gamed::Object::Deck::Rook;

use parent 'Gamed::Object::Deck';

my %TYPE = (
    full        => [ 1 .. 14 ],
    partnership => [ 1, 5 .. 14 ],
);

sub build {
    my ( $self, $type ) = @_;
    $type ||= 'full';
    $self->{type} = exists $TYPE{$type} ? $type : 'full';
}

sub generate_cards {
    my $self = shift;
    my @cards;
    for my $suit ( 'B', 'G', 'R', 'Y' ) {
        for my $v ( @{ $TYPE{$self->{type}} } ) {

            push @cards, "$v$suit";
        }
    }
    push @cards, '0_';
    return \@cards;
}

1;
