package Gamed::Themes;

use IO::Dir;

sub import {
    no strict 'refs';
    no warnings 'redefine';
    my $pkg = caller;
    for my $method (qw/build on_join on_message on_quit/) {
        my $real
          = defined &{"$pkg\::$method"}
          ? \&{"$pkg\::$method"}
          : \&{"Gamed::Game::$method"};
        *{"$pkg\::$method"}  = \&{"Gamed::Themes::$method"};
        *{"$pkg\::_$method"} = $real;
    }
}

sub build {
    my ( $self, $args ) = @_;
    $self->{themes} = load();
    $self->_build($args);
}

sub on_join {
    my ( $self, $client ) = @_;
    $self->_on_join($client);
}

sub on_message {
    my ( $self, $client, $message ) = @_;

    $self->_on_message($client, $message);
}

sub on_quit {
    my ( $self, $player ) = @_;

    $self->_on_quit($player);
}

sub load {
    my @themes;
    my $dir = IO::Dir->new( $Gamed::resources . "/themes" );
    if ( defined $dir ) {
        while ( defined( $_ = $d->read ) ) {
            print Dumper $_;
        }
    }
}

1;
