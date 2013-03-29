package Gamed::Test;

use strict;
use warnings;
use Gamed 'Gamed::Test::Game';
use Exporter 'import';
our @EXPORT = qw/json text client game broadcast broadcasted broadcast_one/;

Module::Pluggable::Object->new( search_path => 'Gamed::Test', require => 1, inner => 0 )->plugins;
{
	no warnings 'redefine';
	*Gamed::Player::send = sub { $_[0]->{sock}->send($_[1]) }; #Don't json encode
}

use Test::Builder;
my $tb = Test::Builder->new;

my $j = JSON->new->convert_blessed;
sub json ($) { $j->encode( $_[0] ) }
sub hash ($) { $j->decode( $_[0] ) }
sub client   { Gamed::Test::Connection->new(shift) }

sub game {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $game, $name, $players, $opts) = @_;
    my @connections;
    my $created = 0;
    for (@$players) {
        my $c = client($_);
        $created ? $c->join($name) : $c->create( $game, $name, $opts );
        $created = 1;
        push @connections, $c;
    }
	my $instance = $Gamed::game_instances{$name};
    broadcast( $instance, {}, 'Broacast of test start' );
    return $instance, @connections;
}

sub broadcasted {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ($game, $client, $msg, @exp) = @_;
    $client->game( $msg );
    for my $p ( @{ $game->{players} } ) {
        $p->{sock}->got_one(@exp);
    }
}

sub broadcast_one {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $game = shift;
    for my $p ( @{ $game->{players} } ) {
        $p->{sock}->got_one(@_);
    }
}

sub broadcast {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $game = shift;
    for my $p ( @{ $game->{players} } ) {
        $p->{sock}->got(@_);
    }
}

1;
