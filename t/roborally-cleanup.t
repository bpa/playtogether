use strict;
use warnings;
use Test::More;
use Gamed;
use Gamed::Test;
use Data::Dumper;
use Gamed::Game::RoboRally::Course;
use t::RoboRally;

cleanup(
    "Repair & Upgrade",
    before => {
        bot('a', 0, 0, N, { damage => 1 }),    #wrench
        bot('b', 5, 5, N, { damage => 2 }),    #floor
        bot('c', 7, 7, N, { damage => 2 }),    #upgrade
        bot('d', 1, 4, N, { damage => 2 }),    #flag 3
        bot('e', 9, 7, N, { damage => 0 }),    #flag 2
    },
    after => {
        bot('a', 0, 0, N, { damage => 0 }),
        bot('b', 5, 5, N, { damage => 2 }),
        bot('c', 7, 7, N, { damage => 1, options => ['Brakes'] }),
        bot('d', 1, 4, N, { damage => 1 }),
        bot('e', 9, 7, N, { damage => 0 }),
    },
    broadcast => { repair  => { a => 1, c => 1, d => 1 }, options => { c => ['Brakes'] } } );

cleanup(
    'Damage related cleanup',
	died => [ 'a' ],
    before => {
        dead('a', 2, {
            locked    => [ 1, 1, 1, 1, 1 ],
            registers => [ ['r90'], ['l60'], ['r70'], ['3840'], ['u20'] ],
            damage    => 10,
        } ),
		archive('a', 7, 9),
        bot('f', 11, 11, N, {    #wrench
            damage    => 7,
            locked    => [ 0, 0, 1, 1, 1 ],
            registers => [ ['r90'], ['l60'], ['r70'], ['3840'], ['u20'] ],
        } ),
    },
    after     => {
        dead('a', 2, { damage => 2 }),
		archive('a', 7, 9),
        bot('f', 11, 11, N, {
            damage    => 6,
            locked    => [ 0, 0, 0, 1, 1 ],
            registers => [ [], [], [], ['3840'], ['u20'] ] } ),
	},
    broadcast => [ 
		  { repair => { f => 1 }, options => {} },
		  { cmd => 'placing', bot => 'a' },
		] );

cleanup(
    'Died by falling',
	died => [ 'c', 'b', 'a' ],
    before => {
        dead('a', 2),
        dead('b', 1),
        dead('c', 0),
    },
    after => {
        dead('a', 2, { damage => 2 }),
        dead('b', 1, { damage => 2 }),
        dead('c', 0),
	},
    broadcast => [
      { repair => {}, options => {}},
	  { cmd => 'placing', bot => 'b' },
	] );

done_testing();

sub cleanup {
    my ( $scenario, %a ) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    subtest $scenario => sub {
        my $p1 = Gamed::Test::Player->new('a');
        my $rally = $p1->create( 'RoboRally', 'test', { course => 'risky_exchange' } );
        $rally->{public}{bots}{a} = {};
        $rally->{public}{course}->add_bot('a');
        $p1->broadcast( { cmd => 'bot', 'bot' => 'a' } );
        for my $p (grep { $_ ne 'a' && !/_archive/ } keys %{$a{before}}) {
            my $p1 = Gamed::Test::Player->new($p);
            $p1->join('test');
            $rally->{public}{bots}{$p} = {};
            $rally->{public}{course}->add_bot($p);
            $p1->broadcast( { cmd => 'bot', 'bot' => $p } );
        }
        while ( my ( $k, $v ) = each %{ $a{before} } ) {
            my $bot = $rally->{public}{course}{pieces}{$k};
            while ( my ( $bk, $bv ) = each %$v ) {
                $bot->{$bk} = $bv;
            }
        }
        $rally->{option_cards} = bless { cards => ['Brakes'] }, 'Gamed::Object::Deck';
        $rally->{state} = undef;
        $rally->change_state('CLEANUP');
        $rally->handle( $p1, { cmd => 1 } );

		my $msg = ref($a{broadcast}) eq 'ARRAY' ? $a{broadcast} : [ $a{broadcast} ];
        $msg->[0]{cmd} = 'cleanup';
		while (my ($name, $bot) = each (%{$a{after}})) {
        	$msg->[0]{bots}{$name} = $bot if $bot->{type} eq 'bot';
		}
		for my $m (@$msg) {
        	$p1->got( $m );
		}

        $p1->{sock}{packets} = [];
        $p1->{game} = Gamed::Lobby->new;
        delete $Gamed::instance{test};
        done_testing();
      }
}
