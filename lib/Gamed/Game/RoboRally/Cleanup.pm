package Gamed::Game::RoboRally::Cleanup;

use Gamed::Handler;
use parent 'Gamed::State';

sub new {
    my ( $pkg, %opts ) = @_;
    bless { name => 'Cleanup' }, $pkg;
}

sub on_enter_state {
    my ( $self, $game ) = @_;

    my @flags;
    for my $p (values %{$game->{public}{course}{pieces}}) {
        $flags[$p->{y}][$p->{x}] = 1 if $p->{type} eq 'flag';
    }
    my %cleanup;
    for my $player ( values %{ $game->{players} } ) {
        my $p    = $player->{public}{bot};
        my $tile = $game->{public}{course}{tiles}[ $p->{y} ][ $p->{x} ];
        if ( $tile->{t} && ( $tile->{t} eq 'upgrade' || $tile->{t} eq 'wrench' ) || $flags[$p->{y}][$p->{x}]) {
            if ( $p->{damage} > 0 ) {
                $p->{damage}--;
                $cleanup{repair}{ $p->{id} } = $p->{damage};
            }
            if ( $tile->{t} eq 'upgrade' ) {
                my $card = $self->{game}{option_cards}->deal;
                if ($card) {
                    push @{ $cleanup{options}{ $p->{id} } }, $card;
                    push @{ $p->{options} }, $card;
                }
            }
        }
    }
    $game->broadcast( cleanup => \%cleanup );

    $game->change_state('PROGRAMMING');
}

1;
