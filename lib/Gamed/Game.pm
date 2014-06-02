package Gamed::Game;

use Gamed::Const;
use Gamed::Handler;
use Gamed::Object;
use Gamed::State;

=head1 NAME

Gamed::Game - Superclass for all games played.

=head1 SYNOPSIS

Sets up the basic event handling, augment with before, on, or after

=cut

before 'join' => sub {
	my ($game, $player, $msg) = @_;
	die "Game full\n" if defined $game->{max_players} && keys(%{ $game->{players} }) >= $game->{max_players};
};

on 'join' => sub {
    my ( $self, $client, $msg ) = @_;
    my $player_id = $self->{ids}{ $client->{id} };
    my $player;

    if ( defined $player_id ) {
        $player = $self->{players}{$player_id};
    }
    else {
        $player_id = $self->{next_player_id}++;
        $player    = {
            in_game_id => $player_id,
            public     => {
                id     => $player_id,
                name   => $client->{name},
                avatar => $client->{avatar} } };
        $self->{players}{$player_id} = $player;
        $self->{ids}{ $client->{id} } = $player_id;
    }

    $player->{client}     = $client;
    $client->{in_game_id} = $player_id;
    $player->{client_id}  = $client->{id};

    my %players;
    for my $p ( values %{ $self->{players} } ) {
        $players{ $p->{in_game_id} } = $p->{public};
    }

    my %msg = ( players => \%players, player => $client->{in_game_id} );
    for my $p ( values %{ $self->{players} } ) {
        $p->{client}->send( join => \%msg ) if defined $p->{client};
    }
};

after 'quit' => sub {
    my ( $self, $client, $msg ) = @_;
    delete $self->{players}{ $client->{in_game_id} }{client};
    $self->broadcast( quit => { player => $client->{in_game_id} } );
    eval {
        if ( !keys %{ $self->{players} } ) {
            delete $Gamed::game_instances{ $self->{name} };
        }
    };
};

sub broadcast {
    my ( $self, $cmd, $msg ) = @_;
    for my $c ( values %{ $self->{players} } ) {
        $c->{client}->send( $cmd, $msg ) if defined $c->{client};
    }
}

1;
