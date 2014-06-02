package Gamed::Game::SpeedRisk::Board;

use JSON::Any;
use File::Slurp;
use File::Spec::Functions 'catdir';

my $json = JSON::Any->new;

sub new {
    my ($pkg, $variant) = @_;
	my $self = bless { variant => $variant }, $pkg;

    my $text = read_file(
        catdir( $Gamed::public, "g", "SpeedRisk", $variant, "board.json" ) );
    die "No board named " . $variant . " known" unless $text;
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

	return $self;
}

1;
