package Gamed::Game;

use Gamed::Const;
use Gamed::State;
use Gamed::Object;

=head1 NAME

Gamed::Game - Superclass for all games played.

=head1 SYNOPSIS

Override whatever you need

=head1 METHODS

=head2 build 

Initialize a game.  L<on_join> will be called immediately following return with the creator of the game.

=cut

sub new {
    my $self = bless { state => Gamed::State->new, next_player_id => 0 }, shift;
    $self->build(@_);
	$self->_change_state if exists $self->{_change_state};
    return $self;
}

sub build { }

=head2 on_join($player) => Game::Const

Handle a player joining.  If the game is full, or there is any issue joining, throw an exception and the player won't be able to join.

=cut

sub on_join {
    my ( $self, $client ) = @_;
    my $player_id = $self->{ids}{ $client->{id} };
    my $player;

    if ( defined $player_id ) {
        $player = $self->{players}{$player_id};
    }
    else {
        $player_id                    = $self->{next_player_id}++;
        $player                       = { in_game_id => $player_id };
        $self->{players}{$player_id}  = $player;
        $self->{ids}{ $client->{id} } = $player_id;
    }

    $player->{client}     = $client;
    $client->{in_game_id} = $player_id;

    my %players;
    $self->{state}->on_join( $self, $client );

    for my $p ( values %{ $self->{players} } ) {
        $players{ $p->{in_game_id} } = {
            name   => $p->{name},
            avatar => $p->{avatar},
            data   => $p->{game_data} };
    }

    my %msg
      = ( cmd => 'join', players => \%players, player => $client->{in_game_id} );
    for my $p ( values %{ $self->{players} } ) {
        $msg{player} = $i;
        $p->{client}->send( \%msg ) if defined $p->{client};
    }

    $self->_change_state if exists $self->{_change_state};
}

=head2 on_message($player, $message)

Handle a message from a player.

=cut

sub on_message {
    my ( $self, $client, $message ) = @_;
    $self->{state}->on_message( $self, $client, $message );
	$self->_change_state if exists $self->{_change_state};
}

=head2 on_quit($player)

Handle a player leaving.

=cut

sub on_quit {
    my ( $self, $player ) = @_;
    $self->{players}[$player->{seat}] = undef;
    $self->{state}->on_quit($player);
}

=head2 on_destroy

Do any cleanup needed before the game is deleted

=cut

sub on_destroy {
}

sub change_state {
	my ($self, $state_name) = @_;
	$self->{_change_state} = $state_name;
}

sub _change_state {
	my $self = shift;
	my $state_name = delete $self->{_change_state};
    my $state = $self->{state_table}{$state_name};
    die "No state '$state_name' found\n" unless defined $state;
    $self->{state}->on_leave_state($self);
    $self->{state} = $state;
    $state->on_enter_state($self);
}

sub broadcast {
    my ( $self, $msg ) = @_;
    for my $c ( @{ $self->{players} } ) {
        $c->send($msg) if defined $c;
    }
}

1;
