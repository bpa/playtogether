package Gamed::Object;

use Module::Pluggable::Object;

sub import {
    Module::Pluggable::Object->new( search_path => shift, require => 1, inner => 0 )->plugins;
}

1;
