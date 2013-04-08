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
    my $self = bless { state => Gamed::State->new }, shift;
    $self->build(@_);
	$self->_change_state if exists $self->{_change_state};
    return $self;
}

sub build { }

=head2 on_join($player) => Game::Const

Handle a player joining.  If the game is full, or there is any issue joining, throw an exception and the player won't be able to join.

=cut

sub on_join {
    my ( $self, $player ) = @_;
    my $reconnected = 0;
    for my $i (0 .. $#{$self->{seat}}) {
        if (exists $self->{seat}[$i]{id} && $self->{seat}[$i]{id} eq $player->{id}) {
            $self->{players}[$i] = $player;
            $reconnected = 1;
        }
    }
    $self->{state}->on_join( $self, $player ) unless $reconnected;
	my %msg = ( cmd => 'join', players => [map { defined $_ ? $_->{name} : $_ } @{$self->{players}}]);
    for my $i ( 0 .. $#{$self->{players}} ) {
		$msg{player} = $i;
		my $p = $self->{players}[$i];
        $p->send(\%msg) if defined $p;
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
