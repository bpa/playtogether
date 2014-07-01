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
    my ( $game, $player, $msg ) = @_;
    die "Game full\n" if defined $game->{max_players} && keys( %{ $game->{players} } ) >= $game->{max_players};
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
            public     => { %{ $client->{user} }, id => $player_id } };
        $self->{players}{$player_id} = $player;
        $self->{ids}{ $client->{id} } = $player_id;
    }

    $player->{client}     = $client;
    $client->{in_game_id} = $player_id;
    $player->{client_id}  = $client->{id};
};

after 'join' => sub {
    my ( $self, $client, $msg ) = @_;
    my $player = $self->{players}{ $client->{in_game_id} };
    $self->broadcast(
        join => { name => $msg->{name}, game => $self->{game}, player => $player->{public} }
    );
};

after 'quit' => sub {
    my ( $self, $client, $msg, $player_data ) = @_;
    delete $player_data->{client};
    $client->{game} = Gamed::Lobby->new;
    $self->broadcast( quit => { player => $client->{in_game_id} } );
	delete_game_if_empty( $self, $client );
};

sub delete_game_if_empty {
    my $self = shift;
    eval {
        unless ( grep { defined $_->{client}{sock} } values %{ $self->{players} } ) {
			for my $c (values %{ $self->{players} }) {
				$c->{client}{game} = Gamed::Lobby->new;
			}
            delete $Gamed::instance{ $self->{name} };
        }
    };
	print $@ if $@;
};

after 'disconnected' => \&delete_game_if_empty;

on 'status' => sub {
    my ( $self, $client, $msg, $player ) = @_;
    my %players;
    for my $p ( values %{ $self->{players} } ) {
        $players{ $p->{public}{id} } = $p->{public};
    }
    $client->send(
        status => {
            id      => $client->{in_game_id},
            private => $player->{private},
            players => \%players,
            status  => $self->{status},
            public  => $self->{public},
            state   => $self->{state}{name} } );
};

sub broadcast {
    my ( $self, $cmd, $msg ) = @_;
    for my $c ( values %{ $self->{players} } ) {
        $c->{client}->send( $cmd, $msg ) if defined $c->{client};
    }
}

sub player {
    my ( $self, $client ) = @_;
    return $self->{players}{ $client->{in_game_id} };
}

1;
