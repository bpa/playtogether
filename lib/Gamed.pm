package Gamed;

use strict;
use warnings;

use File::Basename 'dirname';
use File::Spec::Functions 'catdir';
use Module::Pluggable::Object;
use FindBin;

our $public = catdir( dirname(__FILE__), 'Gamed', 'public' );

our %games;
our %players;
our %game_instances;
our $VERSION = 0.1;

sub import {
    my ( $pgk, $path ) = ( @_, "Gamed::Game" );
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
