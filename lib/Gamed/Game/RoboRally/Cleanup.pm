package Gamed::Game::RoboRally::Cleanup;

use Gamed::Handler;
use parent 'Gamed::State';

sub new {
    my ( $pkg, %opts ) = @_;
    bless { name => 'Cleanup' }, $pkg;
}

sub on_enter_state {
    my ( $self, $game ) = @_;

    my @flags;
    for my $p (values %{$game->{public}{course}{pieces}}) {
        $flags[$p->{y}][$p->{x}] = 1 if $p->{type} eq 'flag';
    }

    my %cleanup = ( repairs => {}, options => {}, pieces => {} );
	$self->{placing} = [];
	$self->{repairs} = 0;

    for my $player ( values %{ $game->{players} } ) {
        my $bot = $player->{public}{bot};
		$cleanup{pieces}{$bot->{id}} = $bot;

		if ($bot->{active}) {
			my $action = $self->tile_actions($bot, \@flags);

			if ( $action->{repairs} ) {
				my $repaired = $self->repair($bot, 1);
				$player->{repairs} = 1 - $repaired;
				$cleanup{repairs}{ $bot->{id} } = $repaired if $repaired;
			}

			if ( $action->{upgrade} ) {
				my $card = $self->upgrade($bot);
				push (@{ $cleanup{options}{ $bot->{id} } }, $card) if $card;
			}

			if ( $player->{repairs} ) {
				$self->{repairs} += $player->{repairs};
			}
		}
        else {
            $self->restore($bot);
        }

		$self->clear_registers($bot);
    }

    $game->broadcast( repairs => \%cleanup );

    for my $piece (@{ $game->{deaths}}) {
        if ($piece->{type} eq 'bot' && $piece->{lives}) {
            push(@{$self->{placing}}, $piece->{id});
        }
    }

    $self->check_for_placing;
}

sub check_for_placing {
    my $self = shift;
    my $game = $self->{game};

    if (@{$self->{placing}}) {
        my $arch = $game->{public}{course}->piece($self->{placing}[0] . '_archive');
        $self->{placing_options} = $game->{public}{course}->available_placements($arch->{x}, $arch->{y});
	    $game->broadcast( placing => { bot => $self->{placing}[0], available => $self->{placing_options} } );
    }
    else {
   	    $game->change_state('PROGRAMMING');
    }
}

sub upgrade {
	my ($self, $bot) = @_;
	my $card = $self->{game}{option_cards}->deal;
	if ($card) {
		push @{ $bot->{options} }, $card;
		return $card;
	}
	return;
}

sub tile_actions {
	my ($self, $bot, $flags) = @_;
	my %action;

	$action{repairs} = 1 if $flags->[$bot->{y}][$bot->{x}];

	my $tile = $self->{game}{public}{course}{tiles}[ $bot->{y} ][ $bot->{x} ];
	return \%action unless $tile->{t};

	$action{repairs} = 1 if $tile->{t} eq 'upgrade' || $tile->{t} eq 'wrench';
	$action{upgrade} = 1 if $tile->{t} eq 'upgrade';
	return \%action;
}

sub repair {
	my ($self, $bot, $damage) = @_;

	if ( $bot->{damage} > 0 ) {
		$bot->{damage}--;

        for ( 0 .. 8 ) {
            if ($bot->{registers}[$_]{damaged}) {
                $bot->{registers}[$_]{damaged} = 0;
                last;
            }
        }

	    return 1;
	}
	return 0;
}

sub restore {
	my ($self, $bot) = @_;
    for my $r (@{$bot->{registers}}) {
        $r->{damaged} = 0;
        $r->{program} = [] if $r->{program};
    }
	if ($bot->{lives}) {
		$bot->{damage} = 2;
        $bot->{registers}[-1]{damaged} = 1;
        $bot->{registers}[-2]{damaged} = 1;
	}
    else {
        $bot->{damage} = 0;
    }
}

sub clear_registers {
	my ($self, $bot) = @_;

	for my $r ( 0 .. 4 ) {
		$bot->{registers}[$r]{program} = [] unless $bot->{registers}[$r]{damaged};
	}
}

on 'place' => sub {
    my ( $self, $player, $msg, $player_data ) = @_;

    if ($player_data->{public}{bot}{id} ne $self->{placing}[0]) {
        $player->err('Not your turn');
        return;
    }

    if (!(defined $msg->{x} && defined $msg->{y})) {
        $player->err("Invalid placement, require x, y");
        return;
    }

    if (!defined $msg->{o} || $msg->{o} < 0 || $msg->{o} > 3) {
        $player->err("Invalid placement, o must be one of 0 - 3");
        return;
    }
    
    if (!$self->valid_placement($msg)) {
        $player->err("Invalid placement");
        return;
    }

    my $game = $self->{game};
    my $course = $game->{public}{course};
    my $bot = $course->piece($self->{placing}[0]);

    $bot->{lives}--;
    $bot->{active} = 1;
    $bot->{o} = $msg->{o};
    $course->move($bot, $msg->{x}, $msg->{y});
    $game->broadcast( place => { piece => $bot } );

    shift @{$self->{placing}};
    $self->check_for_placing;
};

sub valid_placement {
    my ($self, $msg) = @_;

    my $a = $self->{placing_options}{$msg->{x}};
    return unless defined $a;

    $a = $a->{$msg->{y}};
    return unless defined $a;

    return $a->[$msg->{o}];
}

1;
