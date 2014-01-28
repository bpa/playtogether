package Gamed::Themes;

use Moose::Role;
use File::Find;
use File::Basename;
use namespace::autoclean;

has 'themes' => (
    is      => 'ro',
    isa     => 'HashRef',
    lazy    => 1,
    builder => 'load_themes',
);

after 'on_join' => sub {
    my ( $self, $game, $player ) = @_;

    my $unused = $self->themes;
    my $theme  = ( keys %$unused )[ rand keys %$unused ];
    delete $unused->{$theme};
    $player->{public}{theme} = $theme;
};

around 'on_message' => sub {
    my ( $orig, $self, $game, $player, $message ) = @_;
    if ( $message->{cmd} eq 'theme' ) {
        if (   defined $message->{theme}
            && exists $self->{themes}{ $message->{theme} } )
        {
            $self->{themes}{ $player->{public}{theme} } = ();
            $player->{public}{theme} = $message->{theme};
            delete $self->{themes}{ $message->{theme} };
            $game->broadcast(
                {   cmd    => 'theme',
                    theme  => $message->{theme},
                    player => $player->{in_game_id} } );
        }
        else {
            $player->{client}->err("Invalid theme");
        }
    }
    else {
        $self->$orig( $game, $player, $message );
    }
};

before 'on_quit' => sub {
    my ( $self, $game, $player ) = @_;
    $self->{themes}{ delete $player->{public}{theme} } = ();
};

sub load_themes {
    my %themes;
    find sub {
        if ( $_ eq 'theme.properties' ) {
            $themes{ basename($File::Find::dir) } = ();
        }
    }, "$Gamed::resources/themes";
    return \%themes;
}

1;
