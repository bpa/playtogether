package Gamed::State::PlayTricks;

use Gamed::Handler;
use parent 'Gamed::State';

our $| = 1;

sub new {
    my ( $pkg, %opts ) = @_;
    my $self = bless \%opts, $pkg;
    $self->{name} ||= 'PlayTricks';
    die "No logic given\n" unless $self->{logic}->can('is_valid_play');
    return $self;
}

sub on_enter_state {
    my $self = shift;
    for ( 0 .. $#{ $self->{game}{seats} } ) {
        $self->{active_player} = $_ if $self->{game}{seats}[$_] eq $self->{game}{public}{player};
    }
    for ( values $self->{game}{players} ) {
        $_->{taken} = [];
    }
    $self->{game}{public}{trick} = [];
}

on 'play' => sub {
    my ( $self, $client, $msg, $player ) = @_;
    my $game = $self->{game};

    if ( $client->{in_game_id} ne $game->{public}{player} ) {
        $client->err('Not your turn');
        return;
    }
    if ( $self->{logic}->is_valid_play( $msg->{card}, $game->{public}{trick}, $player->{private}{cards}, $game ) ) {
	$game->{public}{leader} = $client->{in_game_id} unless @{ $game->{public}{trick} };
        push @{ $game->{public}{trick} }, $msg->{card};
        $player->{private}{cards}->remove( $msg->{card} );
        $self->{active_player} = ++$self->{active_player} % keys %{ $game->{players} };
        $game->{public}{player} = $game->{seats}[ $self->{active_player} ];
        if ( @{ $game->{public}{trick} } == keys %{ $game->{players} } ) {
            $self->{active_player} = $self->{logic}->trick_winner( $game->{public}{trick}, $game ) + $self->{active_player};
            $self->{active_player} %= keys %{ $game->{players} };
            $game->{public}{player} = $game->{seats}[ $self->{active_player} ];
            $game->broadcast( trick => { trick => $game->{public}{trick}, winner => $game->{public}{player}, leader => $game->{public}{leader} } );
            push @{ $game->{players}{ $game->{public}{player} }{taken} }, @{ $game->{public}{trick} };
            $game->{public}{trick} = [];
            $game->{public}{leader} = [];
            if ( grep ( scalar( $_->{private}{cards}->values ), values %{ $game->{players} } ) == 0 ) {
                $self->{logic}->on_round_end($game);
            }
        }
        else {
            $game->broadcast(
                play => { player => $client->{in_game_id}, card => $msg->{card}, next => $game->{public}{player} } );
        }
    }
    else {
        $client->send( error => { reason => 'Invalid card', card => $msg->{card}, cards => $player->{private}{cards} });
    }
};

1;
