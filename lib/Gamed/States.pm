package Gamed::States;

import Gamed::Handler;

sub import {
    my ( $pkg, $state_table ) = @_;
    my $callpkg = caller(0);
    *{"$callpkg\::change_state"} = \&change_state;
    Gamed::Handler::_install( 'after', '*', \&after_star );
    Gamed::Handler::_install(
        'before', 'create',
        sub {
            my ( $game, $player, $msg ) = @_;
            while ( my ( $k, $v ) = each %$state_table ) {
                $game->{states}{$k} = $v->clone;
				$game->{states}{$k}{game} = $game;
            }
        }
    );
}

sub after_star {
    my ( $game, $player, $msg ) = @_;
    while ( exists $game->{_change_state} ) {
        my $state_name = delete $game->{_change_state};
        my $state      = $game->{states}{$state_name};
        die "No state '$state_name' found\n" unless defined $state;
		my $from = 'none';
        $from = $game->{state}{name} if $game->{state};
        $game->{state}->on_leave_state($game) if $game->{state};
        $game->{state} = $state;
		#print "========= $from > ", $game->{state}{name}, "\n";
        $state->on_enter_state($game);
    }
}

sub change_state {
    my ( $game, $state_name ) = @_;
    $game->{_change_state} = $state_name;
}

1;
