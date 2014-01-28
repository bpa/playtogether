package Gamed::State;

use Gamed::Const;
use Module::Pluggable::Object;
require Exporter;
use Moose;
use namespace::autoclean;

has 'name' => (
	is => 'ro',
	required => 1,
);

sub import {
    Module::Pluggable::Object->new( search_path => shift, require => 1, inner => 0 )
      ->plugins;
}

sub on_message     { }
sub on_enter_state { }
sub on_leave_state { }
sub on_join        { }
sub on_quit        { }

__PACKAGE__->meta->make_immutable;
