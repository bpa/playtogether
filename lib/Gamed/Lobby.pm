package Gamed::Lobby;

use parent 'Gamed::Handler';

on 'games' => sub {
	my ( $game, $player, $msg ) = @_;
	my @inst;
	while ( my ( $k, $v ) = each %game_instances ) {
		push @inst,
		{ name    => $k,
			game    => $v->{game},
			players => [ map { $_->{name} } $v->{players} ],
			status  => $v->{status} };
	}
	$player->send( games => { games => [ sort keys %games ], instances => \@inst } );
}

on 'create' => sub {
    my ( $player, $msg ) = @_;
	die "No name given\n" unless exists $msg->{name};
	die "No game specified\n" unless exists $msg->{game};

    if ( exists $game_instances{ $msg->{name} } ) {
        die "A game named '" . $msg->{name} . "' already exists.\n";
    }
    if ( exists $games{ $msg->{game} } ) {
        eval {
            my $game = $games{ $msg->{game} }->create($msg);
            $game->{name} = $msg->{name};
            $game->{game} = $msg->{game};
            $game_instances{ $msg->{name} } = $game;
            for my $p ( values %players ) {
                $p->send( create => { name => $msg->{name}, game => $msg->{game} } )
                  if defined $p->{sock} && !defined $p->{game};
            }
        };
        if ($@) {
            $game_instances{ $msg->{name} }->on_destroy
              if exists $game_instances{ $msg->{name} };
            delete $game_instances{ $msg->{name} };
            die $@;
        }
    }
    else {
        die "No game type '" . $msg->{game} . "' exists\n";
    }
}

on 'join' => sub {
    my ( $player, $msg ) = @_;
    my $name = $msg->{name};
    if ( !defined( $game_instances{$name} ) ) {
        $player->err("No game named '$name' exists");
    }
    else {
        eval {
            #on_quit($player) if defined $player->{game};
            my $instance = $game_instances{$name};
            $instance->on_join($player);
            $player->{game} = $instance;
        };
        if ($@) {
            $player->err($@);
        }
    }
}

1;
