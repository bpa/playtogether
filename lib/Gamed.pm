package Gamed;

use strict;
use warnings;

use File::Basename 'dirname';
use File::Spec::Functions 'catdir';
use Module::Pluggable::Object;
use FindBin;

our $public = catdir( dirname(__FILE__), 'Gamed', 'public' );

our $VERSION = 0.1;
our %games;

sub import {
    my ( $pkg, $path ) = ( @_, "Gamed::Game" );
    my $finder = Module::Pluggable::Object->new(
        search_path => $path,
        require     => 1,
        inner       => 0
    );
    for my $game ( $finder->plugins ) {
        if ( my ($shortname) = $game =~ /::Game::([^:]+)$/ ) {
            $games{$shortname} = $game;
        }
    }
}

1;
