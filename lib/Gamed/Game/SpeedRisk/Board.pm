package Gamed::Game::SpeedRisk::Board;

use Moose;
use JSON::Any;
use File::Slurp;
use namespace::clean;

has 'variant' => ( is => 'ro', required => 1 );
my $json = JSON::Any->new;

sub BUILD {
    my $self = shift;
    my $text = read_file( "$Gamed::resources/" . $self->variant . "Risk/board.json" );
    die "No board named " . $self->variant . " known" unless $text;
    my $board = $json->decode($text);
    while ( my ( $k, $v ) = each %$board ) {
        $self->{$k} = $v;
    }

    for my $c ( 0 .. $#{ $self->{territories} } ) {
        my $terr = $self->{territories}[$c];
        $terr->{id} = $c;
        $self->{map}{ $terr->{name} } = $terr;
    }

    for my $c ( @{ $self->{territories} } ) {
        for my $b ( @{ $c->{borders} } ) {
            my $border = $self->{map}{$b};
            $c->{border}[ $border->{id} ] = 1;
            $border->{border}[ $c->{id} ] = 1;
        }
    }

    for my $c ( @{ $self->{territories} } ) {
        $c->{borders} = delete $c->{border};
    }

    for my $c ( values %{ $self->{continents} } ) {
        $c->{territories} = [ map { $self->{map}{$_} } @{ $c->{territories} } ];
    }
}

__PACKAGE__->meta->make_immutable;
