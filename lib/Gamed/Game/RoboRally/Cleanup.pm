package Gamed::Game::RoboRally::Cleanup;

use Gamed::Handler;
use parent 'Gamed::State';
use Data::Dumper;

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

	if (@{$self->{placing}}) {
		my $bot = shift @{$self->{placing}};
		$game->{public}{placing} = $bot->{id};
		$game->broadcast( placing => { bot => $bot->{id} } );
	}

    my $need_input = 0;
    for my $piece (@{ $game->{deaths}}) {
        if ($piece->{type} eq 'bot') {
            if (!$need_input) {
                push(@{$self->{placing}}, $piece->{id});
            }
            $need_input = 1;
        }
    }
    $game->change_state('PROGRAMMING') unless $need_input;
   	$game->change_state('PROGRAMMING') unless @{$self->{placing}} || $self->{repairs};
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
		push @{$self->{placing}}, $bot;
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

    my $game = $self->{game};
    my $course = $game->{public}{course};
    $msg->{bot} = $player_data->{public}{bot}{id};
    my $bot = $game->{public}{course}{pieces}{$msg->{bot}};
    my $tile = $course->tile($msg->{x}, $msg->{y});
    if (!defined $tile || grep { $_->{solid} } @{ $tile->{pieces} }) {
        $player->err("Invalid Placement");
        return;
    }

    my $archive = $course->{pieces}{$bot->{id} . "_archive"};
    if ($msg->{x} != $archive->{x} || $msg->{y} != $archive->{y}) {
        $player->err("Invalid Placement");
        return;
    }

    $bot->{damage} = 2;
    $bot->{active} = 1;
    $game->{public}{course}->move($bot, $msg->{x}, $msg->{y});
    $self->{game}->broadcast( place => $msg );
};

1;
