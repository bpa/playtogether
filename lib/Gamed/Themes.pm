package Gamed::Themes;

use File::Find;
use File::Basename;

sub import {
    no strict 'refs';
    no warnings 'redefine';
    my $pkg = caller;
    for my $method (qw/build on_join on_message on_quit/) {
        my $real
          = defined &{"$pkg\::$method"}
          ? \&{"$pkg\::$method"}
          : \&{"Gamed::Game::$method"};
        *{"$pkg\::$method"}         = \&{"Gamed::Themes::$method"};
        *{"$pkg\::_themes_$method"} = $real;
    }
}

sub build {
    my ( $self, $args ) = @_;
    $self->{_themes} = load();
    $self->_themes_build($args);
}

sub on_join {
    my ( $self, $client ) = @_;
    $self->_themes_on_join($client);

    my $unused = $self->{_themes};
    my $theme  = ( keys %$unused )[ rand keys %$unused ];
    delete $unused->{$theme};
    $self->{players}{ $client->{in_game_id} }{public}{theme} = $theme;
}

sub on_message {
    my ( $self, $client, $message ) = @_;
    if ( $message->{cmd} eq 'theme' ) {
        if ( exists $self->{_themes}{ $message->{theme} } ) {
            $self->{_themes}{ $client->{public}{theme} } = ();
            $client->{public}{theme} = $message->{theme};
            delete $self->{_themes}{ $message->{theme} };
            $self->broadcast(
                {   cmd    => 'theme',
                    theme  => $message->{theme},
                    player => $client->{in_game_id} } );
        }
        else {
            $client->err("Invalid theme");
        }
    }
    else {
        $self->_themes_on_message( $client, $message );
    }
}

sub on_quit {
    my ( $self, $player ) = @_;
    $self->{_themes}{ $player->{public}{theme} } = ();
    $self->_themes_on_quit($player);
}

sub load {
    my %themes;
    find sub {
        if ( $_ eq 'theme.properties' ) {
            $themes{ basename($File::Find::dir) } = ();
        }
    }, "$Gamed::resources/themes";
    return \%themes;
}

1;
