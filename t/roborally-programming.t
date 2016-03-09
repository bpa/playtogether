use strict;
use warnings;
use Test::More;
use Test::Deep;
use Gamed;
use Gamed::Test;
use Data::Dumper;

my $p1 = Gamed::Test::Player->new('1');
my $p2 = Gamed::Test::Player->new('2');
my $p3 = Gamed::Test::Player->new('3');
my $p4 = Gamed::Test::Player->new('4');

subtest 'two players' => sub {
    my $rally = setup();
    is( $rally->{players}{0}{private}{cards}->values, 9, "player 1 was dealt 9 cards" );
    $p1->got_one(
        {   cmd   => 'programming',
            cards => code(sub { @{ $_[0] } == 9 })
        } );
    is( $rally->{players}{1}{private}{cards}->values, 9, "player 2 was dealt 9 cards" );
    $p2->got_one(
        {   cmd   => 'programming',
            cards => code(sub { @{ $_[0] } == 9 })
        } );

    done();
};

subtest 'programming' => sub {
    my $rally = setup();
    $p1->reset;
    $p2->reset;
    $p3->reset;
    $p4->reset;

    my @hand = $rally->{players}{0}{private}{cards}->values;

    #Program only one register
    program( $rally, $p1, [0] );

    #Deprogram
    program( $rally, $p1, [] );
    is_deeply( $rally->{players}{0}{private}{registers}, [] );

    #Program must be array of arrays
    $p1->game( { cmd => 'program', registers => [ $hand[0] ] }, { cmd => 'error', reason => "Invalid program" } );

    #Bad format errors before invalid cards
    $p1->game( { cmd => 'program', registers => ['3100'] }, { cmd => 'error', reason => "Invalid program" } );

    #Must hold card to use
    $p1->game( { cmd => 'program', registers => [ ['3100'] ] }, { cmd => 'error', reason => "Invalid card" } );

    #No options to use multiple cards in a register
    $p1->game( { cmd => 'program', registers => [ [ $hand[0], $hand[1] ] ] },
        { cmd => 'error', reason => "Invalid program" } );

    #Can't lock in programming without all registers programmed
    $p1->game( { cmd => 'program', registers => [ [ $hand[0] ], [ $hand[1] ], [ $hand[2] ], [ $hand[3] ] ] },
        { cmd => 'program', registers => ignore() } );
    $p1->game( { cmd => 'ready' }, { cmd => 'error', reason => 'Programming incomplete' } );

    #No phantom 6th register
    $p1->game(
        {   cmd => 'program',
            registers =>
              [ [ $hand[0] ], [ $hand[1] ], [ $hand[2] ], [ $hand[3] ], [ $hand[4] ], [ $hand[5] ] ] },
        { cmd => 'error', reason => "Invalid program" } );

    #Happy path
    program( $rally, $p1, [ 0, 1, 2, 3, 4 ] );

    #Lock program
    program( $rally, $p1, [ 0, 1, 2, 3, 4 ] );
    $p1->broadcast( { cmd => 'ready' }, { cmd => 'ready', player => 0 } );
    program( $rally, $p1, [0], 'Registers are already programmed' );

    done();
};

subtest 'locked registers' => sub {
    my $rally = setup();
    $p1->reset;
    $p2->reset;

    $rally->{players}{0}{public}{bot}{damage}    = 5;
    $rally->{players}{0}{public}{bot}{registers} = [
        { damaged => 0, program => [] },
        { damaged => 0, program => [] },
        { damaged => 0, program => [] },
        { damaged => 0, program => [] },
        { damaged => 1, program => ['u20'] }];
    $rally->{players}{1}{public}{bot}{damage}    = 2;

    $rally->{state}->on_enter_state($rally);

    # Did p1 get set up correctly?
    is_deeply( $rally->{players}{0}{private}{registers}, [] );

    $p1->got_one(
        {   cmd   => 'programming',
            cards => code(sub { @{ $_[0] } == 4 })
        } );
    $p2->got_one(
        {   cmd   => 'programming',
            cards => code(sub { @{ $_[0] } == 7 })
        } );

    # Add a card to simulate 'Extra Memory' option
    $rally->{players}{0}{private}{cards}->add('b0');
    my @hand = $rally->{players}{0}{private}{cards}->values;

    # Register 5 is locked
    program( $rally, $p1, [ 0, 1, 2, 3, 4 ], "Invalid program");
    program( $rally, $p1, [ 0, 1, 2, 3, 'u20' ] );
    program( $rally, $p1, [ 0, 1, 2, 3 ] );

    done();
};

subtest 'dead' => sub {
    my $rally = setup();
    for my $p ( $p1, $p2, $p3, $p4 ) {
        $p->reset;
        $rally->{players}{$p->{in_game_id}}{public}{bot}{lives} = $p->{in_game_id};
    }

    $rally->{state}->on_enter_state($rally);

    is_deeply( $rally->{players}{0}{private}{registers}, [] );
    $p1->got_one( { cmd => 'programming', cards => [] } );

    for my $p ( $p2, $p3, $p4 ) {
        is_deeply( $rally->{players}{ $p->{in_game_id} }{private}{registers}, [] );
        $p->got_one(
            {   cmd   => 'programming',
                cards => code(sub { @{ $_[0] } == 9 })
            } );
    }

    done();
};

subtest 'time up' => sub {
    my $rally = setup();
    $p1->reset;
    $p2->reset;
    $p3->reset;
    $p4->reset;

    program( $rally, $p1, [0] );
    program( $rally, $p2, [ 0, 1 ] );
    program( $rally, $p3, [ 0, 1, 2 ] );
    program( $rally, $p4, [ 0, 1, 2, 3 ] );

    $rally->{state}->handle_time_up($rally);

    for my $p ( $p1, $p2, $p3, $p4 ) {
        is( @{ $rally->{players}{ $p->{in_game_id} }{private}{registers} }, 5 );
        my $register = $rally->{players}{ $p->{in_game_id} }{private}{registers};
        for my $i ( 0 .. 4 ) {
            is( @{ $register->[$i] }, 1 );
        }
    }

    done();
};

subtest 'time up with locked' => sub {
    my $rally = setup();
    $p1->reset;
    $p2->reset;

    $rally->{players}{0}{bot}{damage}    = 5;
    $rally->{players}{0}{bot}{locked}    = [ 0, 0, 0, 0, 1 ];
    $rally->{players}{0}{bot}{registers} = [
        { damaged => 0, program => [] },
        { damaged => 0, program => [] },
        { damaged => 0, program => [] },
        { damaged => 0, program => [] },
        { damaged => 1, program => ['u20'] } ];

    # Simulating a player that has had 'Fire Control' used on them
    $rally->{players}{1}{bot}{locked} = [ 0, 0, 1, 0, 0 ];
    $rally->{players}{1}{bot}{registers} = [
        { damaged => 0, program => [] },
        { damaged => 0, program => [] },
        { damaged => 1, program => ['3840'] },
        { damaged => 0, program => [] },
        { damaged => 0, program => [] } ];

    $rally->{state}->on_enter_state($rally);
    $p1->reset;
    $p2->reset;

    program( $rally, $p1, [0] );
    program( $rally, $p2, [ 0, 1 ] );

    $rally->{state}->handle_time_up($rally);

    is_deeply( $rally->{players}{0}{private}{registers}[4], ['u20'] );
    is_deeply( $rally->{players}{1}{private}{registers}[2], ['3840'] );
    is( @{ $rally->{players}{0}{private}{registers} }, 5 );
    is( @{ $rally->{players}{1}{private}{registers} }, 5 );

    done();
};

sub program {
    my ( $rally, $player, $cards, $reason ) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my @hand = $rally->{players}{ $player->{in_game_id} }{private}{cards}->values;
    my @program;
    for my $c (@$cards) {
        if ( length($c) > 1 ) {
            push @program, [$c];
        }
        else {
            push @program, [ $hand[$c] ];
        }
    }
    $player->handle( { cmd => 'program', registers => \@program } );
    if ($reason) {
        $player->got_one({ cmd => 'error', reason => $reason }, $reason);
    }
    else {
        $player->got_one( { cmd => 'program', registers => $rally->{players}{ $player->{in_game_id} }{private}{registers} } );
    }
}

sub setup {
    my $rally = $p1->create( 'RoboRally', 'test', { course => 'checkmate' } );
    ok( defined $rally->{public}{course}, "public/course is defined" );
    $p2->join('test');
    $p3->join('test');
    $p4->join('test');
    $p1->broadcast( { cmd => 'bot', 'bot' => 'twonky' }, { cmd => 'bot', 'bot' => 'twonky', player => 0 } );
    $p1->broadcast( { cmd => 'ready' }, { cmd => 'ready', player => 0 } );
    $p2->broadcast( { cmd => 'bot', 'bot' => 'twitch' }, { cmd => 'bot', 'bot' => 'twitch', player => 1 } );
    $p2->broadcast( { cmd => 'ready' }, { cmd => 'ready', player => 1 } );
    $p3->broadcast( { cmd => 'bot', 'bot' => 'zoom_bot' }, { cmd => 'bot', 'bot' => 'zoom_bot', player => 2 } );
    $p3->broadcast( { cmd => 'ready' }, { cmd => 'ready', player => 2 } );
    $p4->broadcast( { cmd => 'bot', bot   => 'spin_bot' }, { cmd => 'bot', 'bot' => 'spin_bot', player => 3 } );
    $p4->game( { cmd => 'ready' } );
    broadcast( $rally, { cmd => 'ready', player => 3 }, "Got ready" );
    is( $rally->{state}{name}, 'Programming' );
    broadcast( $rally, { cmd => 'pieces', pieces => ignore() }, "Got pieces" );

    return $rally;
}

sub done {
    for my $p ( $p1, $p2, $p3, $p4 ) {
        $p->{sock}{packets} = [];
        $p->{game} = Gamed::Lobby->new;
    }
    delete $Gamed::instance{test};
    done_testing();
}

done_testing();
