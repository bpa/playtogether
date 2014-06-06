package Gamed::Lobby;

use Gamed::Handler;

sub new { bless {}, shift; }

on 'games' => sub {
    my ( $game, $player, $msg ) = @_;
    my @inst;
    while ( my ( $k, $v ) = each %Gamed::instance ) {
        push @inst,
          {
            name    => $k,
            game    => $v->{game},
            players => [ map { $_->{name} } $v->{players} ],
            status  => $v->{status}
          };
    }
    $player->send( games => { games => [ sort keys %Gamed::game ], instances => \@inst } );
};

on 'create' => sub {
    my ( $game, $player, $msg ) = @_;
    die "No name given\n"     unless exists $msg->{name};
    die "No game specified\n" unless exists $msg->{game};

    if ( exists $Gamed::instance{ $msg->{name} } ) {
        die "A game named '" . $msg->{name} . "' already exists.\n";
    }
    if ( exists $Gamed::game{ $msg->{game} } ) {
        eval {
            my $game = bless {}, $Gamed::game{ $msg->{game} };
            $game->{name}                   = $msg->{name};
            $game->{game}                   = $msg->{game};
            $Gamed::instance{ $msg->{name} } = $game;

			$game->handle( $player, $msg );
            for my $p ( values %Gamed::Login::players ) {
                $p->send( create => { name => $msg->{name}, game => $msg->{game} } )
                  if ref($p->{game}) eq 'Gamed::Lobby';;
            }
        };
        if ($@) {
            delete $Gamed::instance{ $msg->{name} };
            die $@;
        }
    }
    else {
        die "No game type '" . $msg->{game} . "' exists\n";
    }
};

before 'join' => sub {
    my ( $game, $player, $msg ) = @_;
    my $name     = $msg->{name};
    my $instance = $Gamed::instance{$name};
    if ( !defined $instance ) {
        die "No game named '$name' exists\n";
    }
    else {
        $instance->handle( $player, $msg );
        $player->{game} = $instance;
    }
};

1;
