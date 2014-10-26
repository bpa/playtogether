package Gamed::Game::RoboRally::Executing;

use Gamed::Handler;
use parent 'Gamed::State';

sub new {
    my ( $pkg, %opts ) = @_;
    bless { name => 'Executing' }, $pkg;
}

sub on_enter_state {
    my ( $self, $game ) = @_;

    for my $p ( values %{ $game->{players} } ) {
        $p->{public}{ready} = 0;
    }

    $self->{register} = 1;
    $self->{phase}    = 0;
    $self->execute();
}

my @phase = (
    [ \&do_movement => 'movement' ],
    [ \&do_phase    => 'express_conveyors' ],
    [ \&do_phase    => 'conveyors' ],
    [ \&do_phase    => 'pushers' ],
    [ \&do_phase    => 'gears' ],
    [ \&do_phase    => 'lasers' ],
    [ \&do_touches  => 'touches' ],
    [ \&do_end      => 'cleanup' ],
);

sub execute {
    my $self = shift;
    my $game = $self->{game};
    while (1) {
        my $func = $phase[ $self->{phase} ];
        last unless $func->[0]->( $self, $func->[1] );
        $self->{phase}++;
    }
}

sub do_movement {
    my ( $self, $phase ) = @_;
	my $current = $self->{register};
	my @register;
	for my $p ( values %{ $self->{game}{players} } ) {
		push @register, [ $p->{public}{bot} => $p->{private}{registers}[$current] ];
		$p->{public}{registers}[$current] = $p->{private}{registers}[$current];
	}
    my $actions = $self->{game}{public}{course}->do_movement( $current, \@register );
    $self->{game}->broadcast( execute => { phase => $phase, actions => $actions } ) if $actions;
    return 1;
}

sub do_phase {
    my ( $self, $phase ) = @_;
    my $method  = "do_$phase";
    my $actions = $self->{game}{public}{course}->$method( $self->{register} );
    $self->{game}->broadcast( execute => { phase => $phase, actions => $actions } ) if $actions;
    return 1;
}

sub do_touches {
    return 1;
}

sub do_end {
    my $self = shift;

    $self->{phase} = 0;

    if ( ++$self->{register} > 5 ) {
        $self->{game}->change_state("PROGRAMMING");
        return;
    }

    return 1;
}

1;
