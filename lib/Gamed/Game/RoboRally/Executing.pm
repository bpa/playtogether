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
    [ \&do_cleanup  => 'cleanup' ],
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
	my $current = $self->{register} - 1;
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
	my $self = shift;
	my (@board, @touches, %phase);
	for my $p (values %{$self->{game}{public}{course}{pieces}}) {
		if ($p->{type} eq 'bot') {
			my $tile = $self->{game}{public}{course}{tiles}[$p->{y}][$p->{x}];
			if ($tile->{t} && ($tile->{t} eq 'upgrade' || $tile->{t} eq 'wrench')) {
				my $archive = $self->{game}{public}{course}{pieces}{$p->{id} . "_archive"};
				if ($archive->{x} != $p->{x} || $archive->{y} != $p->{y}) {
					$archive->{x} = $p->{x};
					$archive->{y} = $p->{y};
					$phase{archive}{$p->{id}} = { x => $p->{x}, y => $p->{y} };
				}
			}
		}

		for my $e (@{$board[$p->{x}][$p->{y}]}) {
			if ($p->{type} eq 'flag') {
				push @touches, [ $p, $e ];
			}
			elsif ($e->{type} eq 'flag') {
				push @touches, [ $e, $p ];
			}
		}
		push @{$board[$p->{x}][$p->{y}]}, $p;
	}
	@touches = map $_->[0], sort { $a->[1] <=> $b->[1] } map [$_, $_->[0]{flag} || 0 ], @touches;
	for my $t (@touches) {
		my ($flag, $bot) = @$t;
		if ( $flag->{type} eq 'flag' && $bot->{type} eq 'bot') {
			my $archive = $self->{game}{public}{course}{pieces}{$bot->{id} . "_archive"};
			if ($archive->{x} != $bot->{x} || $archive->{y} != $bot->{y}) {
				$archive->{x} = $bot->{x};
				$archive->{y} = $bot->{y};
				$phase{archive}{$bot->{id}} = { x => $bot->{x}, y => $bot->{y} };
			}
			if ($bot->{flag} + 1 == $flag->{flag}) {
				$bot->{flag}++;
				$phase{flag}{$bot->{id}} = $bot->{flag};
			}
		}
	}

	if (keys %phase) {
		$phase{phase} = 'touches';
		$self->{game}->broadcast( execute => \%phase );
	}
    return 1;
}

sub do_cleanup {
    my $self = shift;

    $self->{phase} = -1; # The next step after running this is to increment phase on success

    if ( ++$self->{register} > 5 ) {
        $self->{game}->change_state("PROGRAMMING");
        return;
    }

    return 1;
}

1;
