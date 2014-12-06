
subtest 'dead' => sub {
    my $rally = setup();
    $p1->reset;
    $p2->reset;
    $p3->reset;

	#First death, due to damage
    $rally->{players}{0}{public}{locked}    = [ 0, 0, 1, 1, 1 ];
    $rally->{players}{0}{public}{registers} = [ [], [], ['r70'], ['3840'], ['u20'] ];
    $rally->{players}{0}{public}{damage}    = 10;
    delete $rally->{board}{pieces}{twonky};

	#First death, due to pit
    $rally->{players}{1}{public}{damage}    = 0;
    delete $rally->{board}{pieces}{twitch};

	#Third and final death, due to pit
    $rally->{players}{2}{public}{damage}    = 4;
    $rally->{players}{2}{public}{lives}     = 1;
    delete $rally->{board}{pieces}{zoom_bot};

    $rally->{state}->on_enter_state($rally);

    for my $p ( $p1, $p2 ) {
        is( $rally->{players}{ $p->{in_game_id} }{public}{lives}, 2 );
        is_deeply( $rally->{players}{ $p->{in_game_id} }{private}{registers}, [] );
        $p->got_one(
            {   cmd   => 'programming',
                cards => sub { $_[0]->values == 7 }
            } );
    }
    is( $rally->{players}{2}{public}{lives}, 0 );
    is_deeply( $rally->{players}{2}{private}{registers}, [] );
    $p3->got_one( { cmd   => 'programming', cards => [] } );

    done();
};

