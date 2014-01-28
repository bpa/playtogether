package Gamed::Test;

use strict;
use warnings;
use Gamed 'Gamed::Test::Game';
use Exporter 'import';
our @EXPORT = qw/json text client game broadcast broadcasted broadcast_one error/;

Module::Pluggable::Object->new(
    search_path => 'Gamed::Test',
    require     => 1,
    inner       => 0
)->plugins;

use Test::Builder;
my $tb = Test::Builder->new;

my $j = JSON->new->convert_blessed;
sub json ($) { $j->encode( $_[0] ) }
sub hash ($) { $j->decode( $_[0] ) }
sub client   { Gamed::Test::Player->new(shift) }

sub game {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $players, $opts, $start_state ) = @_;
    $opts->{game} ||= 'Test';
    $opts->{name} ||= 'test';
    Gamed::on_create($opts);
    my @connections;
    my $instance = $Gamed::game_instances{ $opts->{name} };
	my $player_data = delete $opts->{players};
	while (my ($k, $v) = each %$opts) {
		$instance->{$k} = $v;
	}
    for my $i ( 0 .. $#{$players} ) {
        my $player = $players->[$i];
        my $c      = client($player);
        if ( defined $instance->{players}{$i} ) {
            $instance->{next_player_id}++;
            $instance->{ids}{ $c->{id} } = $i;
        }
        Gamed::on_join( $c, $opts->{name} );
        push @connections, $c;
        $_->got( { cmd => 'join' } ) for @connections;
    }
	while (my ($p, $data) = each %$player_data) {
		while (my ($k, $v) = each %$data) {
			$instance->{players}{$p}{$k} = $v;
		}
	}
	if ($start_state) {
		$instance->change_state('start');
	}
	$instance->change_state_if_requested;
    return $instance, @connections;
}

sub broadcasted {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $game, $client, $msg, @exp ) = @_;
    $client->game($msg);
    for my $p ( values %{ $game->{players} } ) {
        $p->{client}{sock}->got(@exp);
    }
}

sub broadcast_one {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $game = shift;
    for my $p ( values %{ $game->{players} } ) {
        $p->{client}{sock}->got_one(@_);
    }
}

sub broadcast {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $game = shift;
    for my $p ( values %{ $game->{players} } ) {
        $p->{client}{sock}->got(@_);
    }
}

sub error ($) {
    return { cmd => 'error', reason => shift };
}

1;
