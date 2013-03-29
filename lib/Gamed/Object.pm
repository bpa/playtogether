package Gamed::Object;

use Module::Pluggable::Object;
Module::Pluggable::Object->new(
    search_path => 'Gamed::Object',
    require     => 1,
    inner       => 0
)->plugins;

use Exporter 'import';

our @EXPORT = 'bag';

sub bag { return Gamed::Object::Bag->new(@_); }

1;
