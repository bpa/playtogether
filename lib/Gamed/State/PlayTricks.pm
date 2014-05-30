package Gamed::State::PlayTricks;

use Gamed::Handler;
use parent 'Gamed::State';

sub new {
    my ( $pkg, $opts ) = @_;
    my $self = bless $opts, $pkg;
    $self->{name} ||= 'PlayTricks';
    die "No logic given\n" unless $self->{logic}->can('is_valid_play');
}

sub on_enter_state {
    my $self = shift;
    $self->{active_player} = $self->{game}->{leader};
    $self->{trick}         = [];
}

on 'play' => sub {
    my ( $self, $player, $msg ) = @_;
    my $game = $self->{game};

    if ( $player->{in_game_id} != $self->{active_player} ) {
        $player->{client}->err('Not your turn');
        return;
    }

    if ( $self->{logic}->is_valid_play( $msg->{play}, $self->{trick}, $player->{cards}, $game ) ) {
        push @{ $self->{trick} }, $msg->{play};
        $player->{cards}->remove( $msg->{play} );
        $game->broadcast( play => { player => $self->{active_player}, play => $msg->{play} } );
        $self->{active_player}++;
        $self->{active_player} = 0 if $self->{active_player} >= keys %{ $game->{players} };
        if ( @{ $self->{trick} } == keys %{ $game->{players} } ) {
            $self->{active_player} = $self->{logic}->trick_winner( $self->{trick}, $game ) + $self->{active_player};
            $self->{active_player} -= keys %{ $game->{players} }
              if $self->{active_player} >= keys %{ $game->{players} };
            $game->broadcast( trick => { trick => $self->{trick}, winner => $self->{active_player} } );
            push @{ $game->{players}{ $self->{active_player} }{taken} }, @{ $self->{trick} };
            $self->{trick} = [];
            if ( grep ( scalar( $_->{cards}->values ), values %{ $game->{players} } ) == 0 ) {
                $self->{logic}->on_round_end($game);
            }
        }
    }
    else {
        $player->{client}->err('Invalid card');
    }
};

1;
