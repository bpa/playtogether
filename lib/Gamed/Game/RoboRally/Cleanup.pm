package Gamed::Game::RoboRally::Cleanup;

use Gamed::Handler;
use parent 'Gamed::State';

sub new {
    my ( $pkg, %opts ) = @_;
    bless { name => 'Cleanup' }, $pkg;
}

sub on_enter_state {
    my ( $self, $game ) = @_;
    $game->change_state('PROGRAMMING');

#    if ( $self->{register} == 5 ) {
#        if ( $p->{public}{damage} > 0 ) {
#            $p->{public}{damage}--;
#            $phase{repair}{ $bot->{id} } = $p->{public}{damage};
#        }
#    }
#
#    for my $player ( values %{ $self->{game}{players} } ) {
#        my $p = $self->{game}{public}{course}{pieces}{ $player->{public}{bot} };
#        if ($p) {
#            my $tile = $self->{game}{public}{course}{tiles}[ $p->{y} ][ $p->{x} ];
#            if ( $tile->{t} && ( $tile->{t} eq 'upgrade' || $tile->{t} eq 'wrench' ) ) {
#                my $archive = $self->{game}{public}{course}{pieces}{ $p->{id} . "_archive" };
#                if ( $archive->{x} != $p->{x} || $archive->{y} != $p->{y} ) {
#                    $archive->{x} = $p->{x};
#                    $archive->{y} = $p->{y};
#                    $phase{archive}{ $p->{id} } = { x => $p->{x}, y => $p->{y} };
#                }
#                if ( $self->{register} == 5 ) {
#                    if ( $player->{public}{damage} > 0 ) {
#                        $player->{public}{damage}--;
#                        $phase{repair}{ $p->{id} } = $player->{public}{damage};
#                    }
#                    if ( $tile->{t} eq 'upgrade' ) {
#                        my $card = $self->{game}{option_cards}->deal;
#                        if ($card) {
#                            push @{ $phase{options}{ $p->{id} } }, $card;
#                            push @{ $player->{public}{options} }, $card;
#                        }
#                    }
#                }
#            }
#        }
#    }
}

1;
