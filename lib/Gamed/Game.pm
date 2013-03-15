package Gamed::Game;

use Gamed::Const;
use Gamed::State;

=head1 NAME

Gamed::Game - Superclass for all games played.

=head1 SYNOPSIS

Override whatever you need

=head1 METHODS

=head2 build 

Initialize a game.  L<on_join> will be called immediately following return with the creator of the game.

=cut

sub new {
	my $self = bless { state => Gamed::State->new }, shift;
	$self->build;
	return $self;
}

sub build {}

=head2 on_join($player) => Game::Const

Handle a player joining.  If the game is full, or there is any issue joining, throw an exception and the player won't be able to join.

=cut

sub on_join {
	my ($self, $player, $message) = @_;
	$self->{state}->on_join($self, $player, $message);
}

=head2 on_message($player, $message)

Handle a message from a player.

=cut

sub on_message {
	my ($self, $message) = @_;
	$self->{state}->on_message($self, $message);
}

=head2 on_quit($player)

Handle a player leaving.

=cut

sub on_quit {
	my ($self, $player) = @_;
	$self->{state}->on_quit($player);
}

=head2 on_destroy

Do any cleanup needed before the game is deleted

=cut

sub on_destroy {
}

sub change_state {
	my ($self, $state_name) = @_;
	my $state = $self->{state_table}{$state_name};
	$self->{state}->on_leave_state($self);
	$self->{state} = $state;
	$state->on_enter_state($self);
}

1;
