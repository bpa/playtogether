package Gamed::Game;

use Gamed::Const;
use Gamed::State;
use Gamed::Object;
use Moose;
use namespace::autoclean;

=head1 NAME

Gamed::Game - Superclass for all games played.

=head1 SYNOPSIS

Override whatever you need

=head1 METHODS

=head2 build 

Initialize a game.  L<on_join> will be called immediately following return with the creator of the game.

=cut

has 'state' => (
    is      => 'ro',
    isa     => 'Gamed::State',
    default => sub { Gamed::State->new( { name => 'Start' } ) },
);

has 'next_player_id' => (
    is  => 'bare',
    isa => 'Int',
);

after 'on_join', 'on_message', 'on_quit' => \&change_state_if_requested;

sub change_state_if_requested {
    my $self = shift;
    if ( exists $self->{_change_state} ) {
        my $state_name = delete $self->{_change_state};
        my $state      = $self->{state_table}{$state_name};
        die "No state '$state_name' found\n" unless defined $state;
        $self->{state}->on_leave_state($self);
        $self->{state} = $state;
        $state->on_enter_state($self);
    }
};

sub create {
	my $instance = shift->new(@_);
	$instance->change_state_if_requested;
	return $instance;
}

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
    $self->state->on_join( $self, $player );

    for my $p ( values %{ $self->{players} } ) {
        $players{ $p->{in_game_id} } = $p->{public};
    }

    my %msg
      = ( players => \%players, player => $client->{in_game_id} );
    for my $p ( values %{ $self->{players} } ) {
        $p->{client}->send( join => \%msg ) if defined $p->{client};
    }
}

=head2 on_message($player, $message)

Handle a message from a player.

=cut

sub on_message {
    my ( $self, $client, $message ) = @_;
    $self->state->on_message( $self, $self->{players}{ $client->{in_game_id} },
        $message );
}

=head2 on_quit($player)

Handle a player leaving.

=cut

sub on_quit {
    my ( $self, $client ) = @_;
    delete $self->{players}{ $client->{in_game_id} }{client};
    $self->broadcast( quit => { player => $client->{in_game_id} } );
    $self->state->on_quit( $self, $self->{players}{ $client->{in_game_id} } );
}

sub change_state {
    my ( $self, $state_name ) = @_;
    $self->{_change_state} = $state_name;
}

sub broadcast {
    my ( $self, $cmd, $msg ) = @_;
    for my $c ( values %{ $self->{players} } ) {
        $c->{client}->send($cmd, $msg) if defined $c->{client};
    }
}

__PACKAGE__->meta->make_immutable;
