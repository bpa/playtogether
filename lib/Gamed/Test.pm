package Gamed::Test;

use strict;
use warnings;
use Gamed::Test::DB;
use Gamed 'Gamed::Test::Game';
use Exporter 'import';
use JSON;
our @EXPORT = qw/json text game broadcast broadcasted broadcast_one error/;

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
    $connections[0]->handle($opts);
    map { $_->got_one( { cmd => 'create', game => $opts->{game}, name => $opts->{name} } ) } @connections;

    #Initialize game to test state
    my $instance = $Gamed::instance{ $opts->{name} };

    #Switch to appropriate state for joining
    if ($pre_join_state) {
        $instance->change_state($pre_join_state);
    }

    #Have all players join
    $instance->handle( $connections[0], { cmd => 'start_test' } );
    for my $c (@connections) {
        $c->handle( { cmd => 'join', name => $opts->{name} } );
        broadcast_one( $instance, { cmd => 'join' } );
    }

    #Initialize all player states
    while ( my ( $p, $data ) = each %$player_data ) {
        while ( my ( $k, $v ) = each %$data ) {
            $instance->{players}{$p}{$k} = $v;
        }
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
