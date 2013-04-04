package Gamed::Test;

use strict;
use warnings;
use Gamed 'Gamed::Test::Game';
use Exporter 'import';
our @EXPORT = qw/json text client game broadcast broadcasted broadcast_one/;

Module::Pluggable::Object->new( search_path => 'Gamed::Test', require => 1, inner => 0 )->plugins;
use Test::Builder;
my $tb = Test::Builder->new;

my $j = JSON->new->convert_blessed;
sub json ($) { $j->encode( $_[0] ) }
sub hash ($) { $j->decode( $_[0] ) }
sub client   { Gamed::Test::Player->new(shift) }

sub game {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $players, $opts ) = @_;
	$opts->{game} ||= 'Test';
	$opts->{name} ||= 'test';
    my @connections;
    Gamed::on_create($opts);
    for (@$players) {
        my $c = client($_);
        $c->join($opts->{name});
		$_->got_one({ cmd => 'join' }) for @connections;
        push @connections, $c;
    }
    my $instance = $Gamed::game_instances{$opts->{name}};
    return $instance, @connections;
}

sub broadcasted {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $game, $client, $msg, @exp ) = @_;
    $client->game($msg);
    for my $p ( @{ $game->{players} } ) {
        $p->{sock}->got(@exp);
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
