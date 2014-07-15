package Gamed::Game::SpeedRisk::Place;

use strict;
use warnings;
use Scalar::Util qw/looks_like_number/;

sub on_place {
    my ( $self, $player, $message, $player_data ) = @_;
    my $game = $self->{game};
    $player->err("No country specified") && return
      unless looks_like_number( $message->{country} );
    my $c = $message->{country};
    $player->err("Invalid country") && return
      unless 0 <= $c && $c <= $#{ $game->{countries} };

    my $country = $game->{countries}[$c];
    $player->err("Not owner") && return
      unless $country->{owner} eq $player->{in_game_id};

    my $armies = $message->{armies} || 0;
    $player->err("Invalid armies") && return
      unless looks_like_number($armies);
    $player->err("Not enough armies") && return
      unless 0 < $armies && $armies <= $player_data->{private}{armies};

    $country->{armies} += $armies;
    $player_data->{private}{armies} -= $armies;

    $player->send( armies => { armies => $player_data->{private}{armies} } );
    $game->broadcast( country => { country => $c, armies => $country->{armies}, owner => $country->{owner} } } );
};

1;
