package Gamed::Game;

use Gamed::Const;
use Gamed::State;

=head1 NAME

Gamed::Game - Superclass for all games played.

=head1 SYNOPSIS

Override whatever you need

=head1 METHODS

=head2 on_create 

Initialize a game.  L<joined> will be called immediately following return with the creator of the game.

=cut

sub on_create {}

sub create {
	my $self = bless { players => {} }, shift;
	$self->on_create;
	return $self;
}

=head2 on_join($player) => Game::Const

Handle a player joining.  If the game is full, or there is any issue joining, throw an exception and the player won't be able to join.

=cut

sub on_join {
	my ($self, $player) = @_;
	die GAME_FULL
		if exists $self->{'max-players'}
		&& scalar(@{$self->{players}}) >= $self->{'max-players'};
	$self->{players}{$player} = ();
	
}

=head2 on_message($player, $message)

Handle a message from a player.

sub on_quit($player)

Handle a player leaving.

=cut

sub on_quit {
	my ($self, $player) = @_;
	delete $self->{players}{$player};
	die GAME_OVER if !$self->{players};
}

=head2 on_destroy

Do any cleanup needed before the game is deleted

=cut

sub on_destroy {
}

sub change_state {
	my ($self, $state) = @_;
	$self->{state}->on_leave($self) if exists $self->{state};
	$self->{state} = $state;
	$state->on_enter($self);
}

1;
