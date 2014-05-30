package Gamed::State;

import Gamed::Handler;
use Module::Pluggable::Object;

sub import {
    Module::Pluggable::Object->new( search_path => shift, require => 1, inner => 0 )->plugins;
}

sub on_enter_state { }
sub on_leave_state { }

1;
