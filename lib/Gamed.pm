package Gamed;

use strict;
use warnings;

use File::Basename 'dirname';
use File::Spec::Functions 'catdir';
use Module::Pluggable::Object;
use FindBin;

our $public = catdir( dirname(__FILE__), 'Gamed', 'public' );

our $VERSION = 0.1;
our %game;
our %instance;
our $TEST = 0;
our $DEV  = 0;

sub import {
    no strict 'refs';
    my $pkg    = shift;
    my $finder = Module::Pluggable::Object->new(
        search_path => 'Gamed::Game',
        require     => 1,
        inner       => 0
    );
    for my $game ( $finder->plugins ) {
        if ( my ($shortname) = $game =~ /::Game::([^:]+)$/ ) {
            next if defined ${"$game\::TEST"} && ${"$game\::TEST"} && !$TEST;
            next if defined ${"$game\::DEV"}  && ${"$game\::DEV"}  && !$DEV;
            $game{$shortname} = $game;
        }
    }
}

1;
