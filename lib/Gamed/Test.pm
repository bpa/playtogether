package Gamed::Test;

use strict;
use warnings;
use Gamed::Test::DB;
use Test::Deep::NoTest;
require Gamed;
$Gamed::DEV = 1;
$Gamed::TEST = 1;
Gamed->import;
use Gamed::Login;
use Exporter 'import';
use JSON::MaybeXS;
use Mojo::Util;
our @EXPORT = qw/json text game broadcast broadcasted broadcast_one error/;

$Gamed::Login::secret = "testing";
Module::Pluggable::Object->new(
    search_path => 'Gamed::Test',
    require     => 1,
    inner       => 0
)->plugins;

use Test::Builder;
my $tb = Test::Builder->new;

my $j = JSON::MaybeXS->new(convert_blessed => 1);
sub json ($) { $j->encode( $_[0] ) }

sub game {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $players, $opts, $post_join_state, $pre_join_state ) = @_;
    my $player_data = delete $opts->{players};

    #Create each player
    my @connections = map { Gamed::Test::Player->new($_) } @$players;

    #Create game with first player
    $opts->{cmd} = 'create';
    $opts->{game} ||= 'Test';
    $opts->{name} ||= 'test';
	$Gamed::game{$opts->{game}} ||= $opts->{game};
    $connections[0]->handle($opts);
    map { $_->got_one( { cmd => 'create', game => $opts->{game}, name => $opts->{name} } ) } @connections;

    #Initialize game to test state
    my $instance = $Gamed::instance{ $opts->{name} };

    #Switch to appropriate state for joining
    if ($pre_join_state) {
        $instance->change_state($pre_join_state);
    }

    #Initialize all player states
    while ( my ( $p, $data ) = each %$player_data ) {
        while ( my ( $k, $v ) = each %$data ) {
            $instance->{players}{$p}{$k} = $v;
        }
    }

    #Have all players join
    $instance->handle( $connections[0], { cmd => 'start_test' } );
    for my $c (@connections) {
        $c->handle( { cmd => 'join', name => $opts->{name} } );
        broadcast( $instance, { cmd => 'join', game => ignore(), name => ignore(), player => ignore() } );
    }

    #Switch to state to be tested
    if ($post_join_state) {
        $instance->change_state($post_join_state);
    }

    $instance->handle( $connections[0], { cmd => 'start_test' } );
    return $instance, @connections;
}

sub broadcasted {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $game, $client, $msg, @exp ) = @_;
    $client->game($msg);
    for my $p ( values %{ $game->{players} } ) {
        $p->{client}{sock}->got(@exp)
          if ref( $p->{client} ) eq 'Gamed::Test::Player';
    }
}

sub broadcast_one {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $game = shift;
    for my $p ( values %{ $game->{players} } ) {
        $p->{client}{sock}->got_one(@_)
          if ref( $p->{client} ) eq 'Gamed::Test::Player';
    }
}

sub broadcast {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $game = shift;
    for my $p ( values %{ $game->{players} } ) {
        $p->{client}{sock}->got(@_)
          if ref( $p->{client} ) eq 'Gamed::Test::Player';
    }
}

sub error ($) {
    return { cmd => 'error', reason => shift };
}

1;
