package Gamed::State;

use Gamed::Const;
use Module::Pluggable::Object;
require Exporter;

sub import {
    Module::Pluggable::Object->new( search_path => shift, require => 1, inner => 0 )
      ->plugins;
}

sub new {
    my ( $pkg, $game, @args ) = @_;
    my $self = bless {}, $pkg;
    $self->build( $game, @args );
    return $self;
}

sub build          { }
sub on_message     { }
sub on_enter_state { }
sub on_leave_state { }
sub on_join        { die GAME_FULL() }
sub on_quit        { die GAME_OVER() }

1;
