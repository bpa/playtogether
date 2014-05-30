package Gamed::State::WaitingForPlayers;

use Gamed::Handler;
use parent 'Gamed::State';

sub new {
    my ( $pkg, $opts ) = @_;
    my $self = bless $opts, $pkg;
    $self->{name} ||= 'WaitingForPlayers';
    die "Missing next state\n" unless $self->{next};
    return $self;
}

sub on_enter_state {
    my ( $self, $game ) = @_;
    if ( defined $game->{seats} ) {
        $self->{available} = $game->{seats};
    }
    $self->{min} = $game->{min_players} || scalar( @{ $game->{seats} } );
    $self->{max} = $game->{max_players} || scalar( @{ $game->{seats} } );
}

on 'join' => sub {
    my ( $self, $player, $msg ) = @_;
    my $game = $self->{game};

    if ( defined $self->{available} ) {
        my $id = shift @{ $self->{available} };
        $game->{ids}{ $player->{client}{id} } = $id;
        $game->{players}{$id}                 = delete $game->{players}{ $player->{in_game_id} };
        $player->{in_game_id}                 = $id;
        $player->{client}{in_game_id}         = $id;
    }
    my $players = grep { defined $_->{client} } values %{ $game->{players} };
    $game->change_state( $self->{next} )
      if $players >= $self->{max};
};

on 'list_players' => sub {
    my ( $self, $player, $msg ) = @_;
    my @players;
    for my $p ( $self->{game}->{players} ) {
        push @players, $p->{public};
    }
    $player->send( 'list_players' => { players => \@players } );
};

on 'ready' => sub {
    my ( $self, $player, $msg ) = @_;
    my $game = $self->{game};
    if ( keys %{ $game->{players} } >= $game->{min_players} ) {
        $player->{ready} = 1;
        $game->broadcast( ready => { player => $player->{in_game_id} } );
        $game->change_state( $self->{next} )
          unless grep { !$_->{ready} } values %{ $game->{players} };
    }
    else {
        $player->{client}->err("Not enough players");
    }
};

on 'not ready' => sub {
    my ( $self, $player, $msg ) = @_;
    my $game = $self->{game};
    $game->{players}{ $player->{in_game_id} }{ready} = 0;
    $game->broadcast( 'not ready' => { player => $player->{in_game_id} } );
};

on 'quit' => sub {
    my ( $self, $player, $msg ) = @_;
    my $game = $self->{game};

    delete $game->{players}{ $player->{in_game_id} };
    delete $game->{ids}{ $player->{client_id} };
    if ( defined( $self->{available} ) ) {
        unshift @{ $self->{available} }, $player->{in_game_id};
    }

    if ( keys %{ $game->{players} } >= $self->{min} ) {
        $game->change_state( $self->{next} )
          unless grep { !$_->{ready} } values %{ $game->{players} };
    }
};

1;
