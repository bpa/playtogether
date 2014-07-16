use strict;
use warnings;

my @not_so_random_numbers;

BEGIN {
    *CORE::GLOBAL::rand = sub {
        return shift @not_so_random_numbers || 0;
    };
}

use Test::More;
use Gamed;
use Gamed::Test;
use Data::Dumper;

my $p1      = Gamed::Test::Player->new('1');
my $p2      = Gamed::Test::Player->new('2');
my $p3      = Gamed::Test::Player->new('3');
my $classic = Gamed::Game::SpeedRisk::Board->new('Classic');

subtest 'moving' => sub {
    my $risk = setup(
        'Eastern Australia' => { owner => 0, armies => 2 },
        'Western Australia' => { owner => 1, armies => 3 },
        'New Guinea'        => { owner => 1, armies => 1 },
        Madagascar          => { owner => 1, armies => 1 }
    );

    #Normal move
    $p2->broadcast(
        {
            cmd    => 'move',
            from   => ind('Western Australia'),
            to     => ind('New Guinea'),
            armies => 2,
        },
        {
            cmd    => 'move',
            result => [
                { country => ind('Western Australia'), armies => 1, owner => 1 },
                { country => ind('New Guinea'),        armies => 3, owner => 1 }
            ]
        }
    );

    #Can't move last guy or more than you have
    $p2->game(
        {
            cmd    => 'move',
            from   => ind('Western Australia'),
            to     => ind('New Guinea'),
            armies => 1
        },
        { reason => 'Not enough armies' }
    );
    $p2->game(
        {
            cmd    => 'move',
            from   => ind('New Guinea'),
            to     => ind('Western Australia'),
            armies => 3
        },
        { reason => 'Not enough armies' }
    );
    $p2->game(
        {
            cmd    => 'move',
            from   => ind('New Guinea'),
            to     => ind('Western Australia'),
            armies => 4
        },
        { reason => 'Not enough armies' }
    );
    $p2->game(
        {
            cmd    => 'move',
            from   => ind('Western Australia'),
            to     => ind('New Guinea'),
            armies => 4
        },
        { reason => 'Not enough armies' }
    );

    #Can't move to same country
    $p1->game( { cmd => 'move', from => 0, to => 0, armies => 1 }, { reason => 'Invalid destination' } );

    #Can't move to non-bordering country
    $p2->game(
        {
            cmd    => 'move',
            from   => ind('Western Australia'),
            to     => ind('Madagascar'),
            armies => 1
        },
        { reason => 'Invalid destination' }
    );

    #Can't move someone elses armies
    $p1->game(
        {
            cmd    => 'move',
            from   => ind('Western Australia'),
            to     => ind('New Guinea'),
            armies => 1
        },
        { reason => 'Not owner' }
    );

    done();
};

subtest 'attack with one army' => sub {
    my $risk = setup(
        'Western Australia' => { owner => 0, armies => 5 },
        'New Guinea'        => { owner => 1, armies => 5 }
    );

    #Attacker wins
    @not_so_random_numbers = ( 5, 1 );
    $p1->broadcast(
        {
            cmd    => 'move',
            from   => ind('Western Australia'),
            to     => ind('New Guinea'),
            armies => 1
        },
        {
            cmd    => 'attack',
            result => [
                { country => ind('Western Australia'), armies => 5, owner => 0 },
                { country => ind('New Guinea'),        armies => 4, owner => 1 }
            ]
        }
    );

    #Tie
    @not_so_random_numbers = ( 5, 5 );
    $p1->broadcast(
        {
            cmd    => 'move',
            from   => ind('Western Australia'),
            to     => ind('New Guinea'),
            armies => 1
        },
        {
            cmd    => 'attack',
            result => [
                { country => ind('Western Australia'), armies => 4, owner => 0 },
                { country => ind('New Guinea'),        armies => 4, owner => 1 }
            ]
        }
    );

    #Attacker loses
    @not_so_random_numbers = ( 1, 5 );
    $p1->broadcast(
        {
            cmd    => 'move',
            from   => ind('Western Australia'),
            to     => ind('New Guinea'),
            armies => 1
        },
        {
            cmd    => 'attack',
            result => [
                { country => ind('Western Australia'), armies => 3, owner => 0 },
                { country => ind('New Guinea'),        armies => 4, owner => 1 }
            ]
        }
    );

    done();
};

subtest 'attack order' => sub {
    my $risk = setup(
        'Western Australia' => { owner => 0, armies => 10 },
        'New Guinea'        => { owner => 1, armies => 10 }
    );

    #Attacker wins
    @not_so_random_numbers = ( 2, 3, 5, 2, 3 );
    $p1->broadcast(
        {
            cmd    => 'move',
            from   => ind('Western Australia'),
            to     => ind('New Guinea'),
            armies => 3
        },
        {
            cmd    => 'attack',
            result => [
                { country => ind('Western Australia'), armies => 10, owner => 0 },
                { country => ind('New Guinea'),        armies => 8,  owner => 1 }
            ]
        }
    );

    done();
};

subtest 'valid attacks with more than one army' => sub {
    my $risk = setup(
        'Western Australia' => { owner => 0, armies => 10 },
        'New Guinea'        => { owner => 1, armies => 10 }
    );

    #Attacker wins
    @not_so_random_numbers = ( 5, 3, 4, 2 );
    $p1->broadcast(
        {
            cmd    => 'move',
            from   => ind('Western Australia'),
            to     => ind('New Guinea'),
            armies => 2
        },
        {
            cmd    => 'attack',
            result => [
                { country => ind('Western Australia'), armies => 10, owner => 0 },
                { country => ind('New Guinea'),        armies => 8,  owner => 1 }
            ]
        }
    );

    #Attacker wins & ties
    @not_so_random_numbers = ( 5, 5, 5, 4 );
    $p1->broadcast(
        {
            cmd    => 'move',
            from   => ind('Western Australia'),
            to     => ind('New Guinea'),
            armies => 2
        },
        {
            cmd    => 'attack',
            result => [
                { country => ind('Western Australia'), armies => 9, owner => 0 },
                { country => ind('New Guinea'),        armies => 7, owner => 1 }
            ]
        }
    );

    #Attacker ties & loses
    @not_so_random_numbers = ( 3, 5, 5, 4 );
    $p1->broadcast(
        {
            cmd    => 'move',
            from   => ind('Western Australia'),
            to     => ind('New Guinea'),
            armies => 2
        },
        {
            cmd    => 'attack',
            result => [
                { country => ind('Western Australia'), armies => 7, owner => 0 },
                { country => ind('New Guinea'),        armies => 7, owner => 1 }
            ]
        }
    );

    #Attacker loses
    @not_so_random_numbers = ( 3, 2, 5, 4 );
    $p1->broadcast(
        {
            cmd    => 'move',
            from   => ind('Western Australia'),
            to     => ind('New Guinea'),
            armies => 2
        },
        {
            cmd    => 'attack',
            result => [
                { country => ind('Western Australia'), armies => 5, owner => 0 },
                { country => ind('New Guinea'),        armies => 7, owner => 1 }
            ]
        }
    );

    done();
};

subtest 'bad attacks' => sub {
    my $risk = setup(
        'Siam'              => { owner => 0, armies => 1 },
        'Eastern Australia' => { owner => 0, armies => 2 },
        'Western Australia' => { owner => 0, armies => 3 },
        'Indonesia'         => { owner => 1, armies => 1 },
        'New Guinea'        => { owner => 1, armies => 1 },
        Madagascar          => { owner => 1, armies => 1 }
    );

    #Can't attack with no one
    $p1->game(
        {
            cmd    => 'move',
            from   => ind('Siam'),
            to     => ind('Indonesia'),
            armies => 0
        },
        { reason => 'Not enough armies' }
    );

    #Can't attack with last guy or more than you have
    $p1->game(
        {
            cmd    => 'move',
            from   => ind('Western Australia'),
            to     => ind('New Guinea'),
            armies => 3
        },
        { reason => 'Not enough armies' }
    );

    $p2->game(
        {
            cmd    => 'move',
            from   => ind('New Guinea'),
            to     => ind('Western Australia'),
            armies => 1
        },
        { reason => 'Not enough armies' }
    );

    $p2->game(
        {
            cmd    => 'move',
            from   => ind('New Guinea'),
            to     => ind('Western Australia'),
            armies => 3
        },
        { reason => 'Not enough armies' }
    );

    $p2->game(
        {
            cmd    => 'move',
            from   => ind('New Guinea'),
            to     => ind('Western Australia'),
            armies => 4
        },
        { reason => 'Not enough armies' }
    );

    $p1->game(
        {
            cmd    => 'move',
            from   => ind('Western Australia'),
            to     => ind('New Guinea'),
            armies => 4
        },
        { reason => 'Not enough armies' }
    );

    #Can't attack to non-bordering country
    $p1->game(
        {
            cmd    => 'move',
            from   => ind('Western Australia'),
            to     => ind('Madagascar'),
            armies => 1
        },
        { reason => 'Invalid destination' }
    );

    #Can't attack unless you own from
    $p1->game(
        {
            cmd    => 'move',
            from   => ind('New Guinea'),
            to     => ind('Eastern Australia'),
            armies => 1
        },
        { reason => 'Not owner' }
    );

    $p2->game(
        {
            cmd    => 'move',
            from   => ind('Eastern Australia'),
            to     => ind('New Guinea'),
            armies => 0
        },
        { reason => 'Not owner' }
    );

    done();
};

subtest 'place' => sub {
    my $risk = setup();

    #Don't have armies to place
    $risk->{players}{0}{private}{armies} = 0;
    $p1->game( { cmd => 'place', country => 0, armies => 0 }, { cmd => 'error', reason => 'Not enough armies' } );

    #Try to place more than you have
    $risk->{players}{0}{private}{armies} = 10;
    $p1->game( { cmd => 'place', country => 0, armies => 16 }, { cmd => 'error', reason => 'Not enough armies' } );

    #Normal placement
    $p1->game( { cmd => 'place', country => 0, armies => 1 } );
    $p1->got( { cmd => 'armies', armies => 9 } );
    broadcast( $risk, { cmd => 'country', country => { id => 0, armies => 2, owner => 0 } } );
    is( $risk->{players}{0}{private}{armies}, 9 );

    $p1->game( { cmd => 'place', country => 0, armies => 5 } );
    $p1->got( { cmd => 'armies', armies => 4 } );
    broadcast( $risk, { cmd => 'country', country => { id => 0, armies => 7, owner => 0 } } );
    is( $risk->{players}{0}{private}{armies}, 4 );

    #Negative armies
    $p1->game( { cmd => 'place', country => 0, armies => -1 }, { cmd => 'error', reason => 'Not enough armies' } );

    #Can't place on other people's countries
    $p1->game( { cmd => 'place', country => 1, armies => 1 }, { cmd => 'error', reason => 'Not owner' } );

    done();
};

subtest 'produce armies for countries' => sub {
    my $risk = setup();
    clear_board($risk);

    $risk->{countries}[ ind('Eastern US') ]{owner}   = 1;
    $risk->{countries}[ ind('Venezuela') ]{owner}    = 1;
    $risk->{countries}[ ind('North Africa') ]{owner} = 1;
    $risk->{countries}[ ind('Iceland') ]{owner}      = 1;
    $risk->{countries}[ ind('Japan') ]{owner}        = 1;
    $risk->{countries}[ ind('New Guinea') ]{owner}   = 1;

    $risk->{players}{0}{countries} = 4;
    $risk->{players}{1}{countries} = 11;
    $risk->{players}{2}{countries} = 12;

    $risk->{states}{PLAYING}->generate_armies($risk);
    broadcast( $risk, { cmd => 'army timer' } );

    $p1->got( { cmd => 'armies', armies => 3 } );
    $p2->got( { cmd => 'armies', armies => 3 } );
    $p3->got( { cmd => 'armies', armies => 4 } );

    my $i;
    for my $p ( values %{ $risk->{players} } ) {
        $p->{countries} = 30 + $i++;
        $p->{armies}    = 0;
    }

    $risk->{states}{PLAYING}->generate_armies($risk);

    for $i ( 0 .. 2 ) {
        is( $risk->{players}{$i}{armies}, 10 );
    }

    done();
};

subtest 'produce armies for continents' => sub {
    my $risk = setup();
    clear_board($risk);

    $risk->{countries}[ ind('Eastern US') ]{owner} = 1;
    $risk->{countries}[ ind('Venezuela') ]{owner}  = 1;
    $risk->{countries}[ ind('New Guinea') ]{owner} = 1;

    $risk->{countries}[ ind('Iceland') ]{owner}         = 1;
    $risk->{countries}[ ind('Southern Europe') ]{owner} = 1;
    $risk->{countries}[ ind('Ukraine') ]{owner}         = 1;
    $risk->{countries}[ ind('Scandinavia') ]{owner}     = 1;
    $risk->{countries}[ ind('Great Britain') ]{owner}   = 1;
    $risk->{countries}[ ind('Western Europe') ]{owner}  = 1;
    $risk->{countries}[ ind('Northern Europe') ]{owner} = 1;

    $risk->{countries}[ ind('Egypt') ]{owner}        = 2;
    $risk->{countries}[ ind('Congo') ]{owner}        = 2;
    $risk->{countries}[ ind('Madagascar') ]{owner}   = 2;
    $risk->{countries}[ ind('South Africa') ]{owner} = 2;
    $risk->{countries}[ ind('East Africa') ]{owner}  = 2;
    $risk->{countries}[ ind('North Africa') ]{owner} = 2;

    $risk->{states}{PLAYING}->generate_armies($risk);
    broadcast( $risk, { cmd => 'army timer' } );

    $p1->got( { armies => 10 }, '3 + Asia (7) = 10' );
    $p2->got( { armies => 8 },  '3 + Europe(5) = 8' );
    $p3->got( { armies => 6 },  '3 + Africa(3) = 6' );

    clear_board($risk);
    $risk->{countries}[ ind('Iceland') ]{owner}      = 2;
    $risk->{countries}[ ind('North Africa') ]{owner} = 1;
    $risk->{countries}[ ind('South Africa') ]{owner} = 1;
    $risk->{countries}[ ind('Japan') ]{owner}        = 1;

    $risk->{countries}[ ind('Brazil') ]{owner}    = 1;
    $risk->{countries}[ ind('Venezuela') ]{owner} = 1;
    $risk->{countries}[ ind('Argentina') ]{owner} = 1;
    $risk->{countries}[ ind('Peru') ]{owner}      = 1;

    $risk->{countries}[ ind('New Guinea') ]{owner}        = 2;
    $risk->{countries}[ ind('Indonesia') ]{owner}         = 2;
    $risk->{countries}[ ind('Western Australia') ]{owner} = 2;
    $risk->{countries}[ ind('Eastern Australia') ]{owner} = 2;

    $risk->{states}{PLAYING}->generate_armies($risk);
    broadcast( $risk, { cmd => 'army timer' } );

    $p1->got( { armies => 8 }, '3 + N. Am(5) = 8' );
    $p2->got( { armies => 5 }, '3 + S. Am(2) = 5' );
    $p3->got( { armies => 5 }, '3 + Austr(2) = 5' );

    done();
};

subtest 'win game' => sub {
    my $risk = setup(
        'Western Australia' => { owner => 0, armies => 9 },
        'Eastern Australia' => { owner => 1, armies => 1 }
    );

    for my $i ( 0 .. 39 ) {
        $risk->{countries}[$i]{owner}  = 0;
        $risk->{countries}[$i]{armies} = 1;
    }

    $risk->{players}{0}{countries} = 41;
    $risk->{players}{1}{countries} = 1;
    $risk->{players}{2}{countries} = 0;

    @not_so_random_numbers = ( 5, 5, 4, 4 );
    $p1->game(
        {
            cmd    => 'move',
            from   => ind('Western Australia'),
            to     => ind('Eastern Australia'),
            armies => 8
        }
    );
    broadcast(
        $risk,
        {
            cmd    => 'attack',
            result => [
                { country => ind('Western Australia'), armies => 1, owner => 0 },
                { country => ind('Eastern Australia'), armies => 8, owner => 0 }
            ]
        }
    );

    broadcast( $risk, { cmd => 'defeated',  player => 1 } );
    broadcast( $risk, { cmd => 'victory', player => 0 } );
    is( $risk->{state}{name}, 'GameOver' );

    done();
};

subtest 'last player wins by default' => sub {
    my $risk = setup();
    $p1->quit();
    $p2->game( { cmd => 'quit' } );

    broadcast( $risk, { cmd => 'victory', player => 2 } );
    broadcast( $risk, { cmd => 'quit',    player => 1 } );
    is( $risk->{state}{name}, 'GameOver' );

    done();
};

sub done {
    for my $p ( $p1, $p2, $p3 ) {
        $p->{sock}{packets} = ();
        $p->{game} = Gamed::Lobby->new;
    }
    delete $Gamed::instance{test};
    done_testing();
}

sub setup {
    my %country = @_;
    my $risk = $p1->create( 'SpeedRisk', 'test', { board => 'Classic' } );
    $p2->join('test');
    $p3->join('test');

    $p1->broadcast( { cmd => 'ready' } );
    $p2->broadcast( { cmd => 'ready' } );
    $p3->game( { cmd => 'ready' } );
    broadcast( $risk, { cmd   => 'ready' } );
    broadcast( $risk, { cmd   => 'armies' } );
    broadcast( $risk, { state => 'Placing' } );
    is( $risk->{state}{name}, 'Placing' );

    $p1->broadcast( { cmd => 'ready' } );
    $p2->broadcast( { cmd => 'ready' } );
    $p3->game( { cmd => 'ready' } );
    broadcast( $risk, { cmd   => 'ready' } );
    broadcast( $risk, { state => 'Playing' } );
    is( $risk->{state}{name}, 'Playing' );

    for my $i ( 0 .. 2 ) {
        $risk->{countries}[$i]{owner}   = $i;
        $risk->{countries}[$i]{armies}  = 1;
        $risk->{players}{$i}{countries} = 14;
    }

    while ( my ( $k, $v ) = each %country ) {
        my $c = $risk->{board}{map}{$k};
        while ( my ( $kk, $vv ) = each %$v ) {
            $c->{$kk} = $vv;
        }
    }
    return $risk;
}

sub clear_board {
    my $risk = shift;

    #This is a completely invalid state, but useful
    for my $i ( 0 .. 41 ) {
        $risk->{countries}[$i]{owner}  = 0;
        $risk->{countries}[$i]{armies} = 1;
    }
    for my $p ( values %{ $risk->{players} } ) {
        $p->{countries} = 1;
        $p->{armies}    = 0;
    }
}

sub ind {
    return $classic->{map}{ $_[0] }{id};
}

done_testing();
