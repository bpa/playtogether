use strict;
use warnings;
use Test::More;
use Gamed;
use Gamed::Test;

my $p1 = Gamed::Test::Player->new('1');
my $p2 = Gamed::Test::Player->new('2');
my $p3 = Gamed::Test::Player->new('3');
my $p4 = Gamed::Test::Player->new('4');

subtest 'Multi-Join' => sub {
    Gamed::on_create( { game => 'SpeedRisk', name => 'test', board => 'Classic' } );
    my $risk = $Gamed::game_instances{test};
    Gamed::on_join( $p1, 'test' );
    broadcast_one( $risk, { cmd => 'join', players => [ { name => '1', avatar => undef } ], player => 0 } );
    is( $p1->{seat}, 0 );
    is( ~~ @{$risk->{players}}, 1 );

    Gamed::on_join( $p2, 'test' );
    broadcast_one( $risk, { cmd => 'join', players => [ { name => '1', avatar => undef }, { name => '2', avatar => undef } ], player => 1 } );
    is( $p2->{seat}, 1 );
    is( ~~ @{$risk->{players}}, 2 );
    delete $Gamed::game_instances{test};
    done_testing();
};

done_testing();

__DATA__
TEST_F(SpeedRiskJoiningTest, join) {
    srd->players[0].ready = 1;
    srd->players[1].ready = 1;
    player_join(game, &p1);
    ASSERT_EQ(SR_CMD_PLAYER_JOIN, all_res->command);
    ASSERT_EQ(0, p1.in_game_id);
    ASSERT_EQ(1, game->playing);
    ASSERT_EQ(0, srd->players[0].ready);
    ASSERT_EQ(1, game->accepting_players);
    simple_command_plr_test(&p1, SR_CMD_READY, SR_CMD_ERROR);
    player_join(game, &p2);
    ASSERT_EQ(SR_CMD_PLAYER_JOIN, all_res->command);
    ASSERT_EQ(1, p2.in_game_id);
    ASSERT_EQ(2, game->playing);
    ASSERT_EQ(0, srd->players[1].ready);
    simple_command_all_test(&p1, SR_CMD_READY, SR_CMD_READY);
    simple_command_all_test(&p2, SR_CMD_READY, SR_CMD_READY);
	ASSERT_EQ(0, game->accepting_players);
    all_res = (SR_Command*)&mock_all_buff[1];
    ASSERT_EQ(SR_CMD_START_PLACING, all_res->command);
    ASSERT_EQ(&SR_PLACING, game->state);
}

TEST_F(SpeedRiskJoiningTest, not_ready) {
    player_join(game, &p1);
    ASSERT_EQ(1, game->playing);
    simple_command_plr_test(&p1, SR_CMD_READY, SR_CMD_ERROR);
    player_join(game, &p2);
    simple_command_plr_test(&p1, SR_CMD_NOTREADY, SR_CMD_ERROR);
    simple_command_all_test(&p2, SR_CMD_READY, SR_CMD_READY);
    simple_command_plr_test(&p2, SR_CMD_READY, SR_CMD_ERROR);
    ASSERT_EQ(&SR_WAITING_FOR_PLAYERS, game->state);
    simple_command_all_test(&p2, SR_CMD_NOTREADY, SR_CMD_NOTREADY);
    simple_command_all_test(&p1, SR_CMD_READY, SR_CMD_READY);
    ASSERT_EQ(&SR_WAITING_FOR_PLAYERS, game->state);
    simple_command_all_test(&p2, SR_CMD_READY, SR_CMD_READY);
    all_res = (SR_Command*)&mock_all_buff[1];
    ASSERT_EQ(SR_CMD_START_PLACING, all_res->command);
    ASSERT_EQ(&SR_PLACING, game->state);
	ASSERT_EQ(0, game->accepting_players);
}

TEST_F(SpeedRiskJoiningTest, drop_rejoin_out_of_order) {
    player_join(game, &p1);
	ASSERT_EQ(1, game->playing);
    player_join(game, &p2);
	ASSERT_EQ(2, game->playing);
    player_join(game, &p3);
	ASSERT_EQ(3, game->playing);
    player_quit(game, &p2);
	ASSERT_EQ(2, game->playing);
    ASSERT_EQ(0, p1.in_game_id);
    ASSERT_EQ(2, p3.in_game_id);
    player_join(game, &p2);
	ASSERT_EQ(3, game->playing);
    ASSERT_EQ(1, p2.in_game_id);
}

TEST_F(SpeedRiskJoiningTest, can_start_with_dropped_player) {
    player_join(game, &p1);
    player_join(game, &p2);
    player_join(game, &p3);
    player_quit(game, &p1);

    simple_command_all_test(&p2, SR_CMD_READY, SR_CMD_READY);
    simple_command_all_test(&p3, SR_CMD_READY, SR_CMD_READY);

    all_res = (SR_Command*)&mock_all_buff[1];
    ASSERT_EQ(SR_CMD_START_PLACING, all_res->command);
    ASSERT_EQ(&SR_PLACING, game->state);
	ASSERT_EQ(0, game->accepting_players);
}

TEST_F(SpeedRiskJoiningTest, drop_unready_player_starts_game) {
    player_join(game, &p1);
    player_join(game, &p2);
    player_join(game, &p3);
    simple_command_all_test(&p2, SR_CMD_READY, SR_CMD_READY);
    simple_command_all_test(&p3, SR_CMD_READY, SR_CMD_READY);
    ASSERT_EQ(&SR_WAITING_FOR_PLAYERS, game->state);

    player_quit(game, &p1);
    ASSERT_EQ(SR_CMD_PLAYER_QUIT, all_res->command);
    all_res = (SR_Command*)&mock_all_buff[1];
    ASSERT_EQ(SR_CMD_START_PLACING, all_res->command);
    ASSERT_EQ(&SR_PLACING, game->state);
	ASSERT_EQ(0, game->accepting_players);
}

TEST_F(SpeedRiskJoiningTest, drop_unready_player_still_requires_two) {
    player_join(game, &p1);
    player_join(game, &p2);
    simple_command_all_test(&p2, SR_CMD_READY, SR_CMD_READY);
    ASSERT_EQ(&SR_WAITING_FOR_PLAYERS, game->state);

    player_quit(game, &p1);
    ASSERT_EQ(SR_CMD_PLAYER_QUIT, all_res->command);
    ASSERT_EQ(&SR_WAITING_FOR_PLAYERS, game->state);
}

TEST_F(SpeedRiskJoiningTest, theme) {
	set_random(0, 0, 5, 5);
	ASSERT_EQ(6, srd->num_themes);
	char *themes[6];
	int i = 0;
	for (Theme *t = srd->themes.lh_first; t != NULL; t = t->themes.le_next) {
		themes[i++] = t->name;
	}
    player_join(game, &p1);
	ASSERT_STREQ(themes[0], srd->players[0].theme->name);
    player_join(game, &p2);
	ASSERT_STREQ(themes[1], srd->players[1].theme->name);
    player_join(game, &p3);
	ASSERT_STREQ(themes[5], srd->players[2].theme->name);
    player_join(game, &p4);
	ASSERT_STREQ(themes[2], srd->players[3].theme->name);
}

TEST_F(SpeedRiskJoiningTest, set_theme) {
    player_join(game, &p1);
    player_join(game, &p2);

	set_theme(p1, NULL, SR_ERR_INVALID_THEME);
	set_theme(p1, "|", SR_ERR_INVALID_THEME);
	set_theme(p1, "test", SR_CMD_SET_THEME);
	set_theme(p2, "test", SR_ERR_INVALID_THEME);
	ASSERT_STREQ("\5\4test", p1.game_data_str);
}

TEST_F(SpeedRiskJoiningTest, max_players) {
    int i;
    Player players[SR_MAX_PLAYERS];
    for (i=0; i<SR_MAX_PLAYERS; i++) {
    	player_join(game, &players[i]);
        ASSERT_EQ(i+1, game->playing);
    }
    ASSERT_EQ(0, game->accepting_players);
    all_res = (SR_Command*)&mock_all_buff[1];
    ASSERT_EQ(SR_CMD_START_PLACING, all_res->command);
    ASSERT_EQ(&SR_PLACING, game->state);
}

TEST_F(SpeedRiskJoiningTest, quit_when_all_leave) {
    player_join(game, &p1);
    ASSERT_EQ(1, game->playing);
    player_quit(game, &p1);
    ASSERT_EQ(0, all_res->command);
    ASSERT_EQ(1, game_quit);
    game = create_instance(&SpeedRisk);
    srd = (SpeedRiskData*)game->data;
}


	void set_theme(Player p, const char *name, int exp) {
		reset_mocks();
		SR_Status_Command *command = (SR_Status_Command*)&buff[0];
		command->command = SR_CMD_SET_THEME;
		command->player = 200;
		if (name == NULL) {
			command->length = 0;
		}
		else {
			command->length = strlen(name);
			strcpy(&buff[4], name);
		}
		player_event(game, &p, (char*)command, 4 + command->length);
		printf("%s: %i\n", name, exp);
		if (exp == SR_CMD_SET_THEME) {
			SR_Status_Command *c = (SR_Status_Command*)&mock_plr_buff[0];
			ASSERT_EQ(exp, c->command);
			ASSERT_EQ(p.in_game_id, c->player);
			ASSERT_EQ(command->length, c->length);
			if (name == NULL) {
				strcpy(buff, "player");
				buff[6] = p.in_game_id + 48;
				buff[7] = '\0';
				ASSERT_EQ(0, c->length);
				ASSERT_STREQ(buff, srd->players[p.in_game_id].theme->name);
			}
			else {
				ASSERT_EQ(command->length, c->length);
				ASSERT_STREQ(name, srd->players[p.in_game_id].theme->name);
			}
		}
		else {
			ASSERT_EQ(exp, plr_res->command);
		}
	}

