extends TestCase


func test_victory_policy_distinguishes_no_override_and_not_finished() -> void:
	var c := make_game(make_board(),[fig("thug",0,Vector2(2,2)),fig("thug",1,Vector2(20,20))],Dice.new(11))
	var standing: Array[int]=[0,1]
	check(RuleHooks.first("scenario_victory",[c,standing])==null)
	c.state.scenario_special=RedKingRingworld.ID
	check(RuleHooks.first("scenario_victory",[c,standing])!=null)
	c.state.scenario_special=""
	check(not c._flow._check_victory())
	c.state.figure(2).out_of_action=true
	check(c._flow._check_victory())
	check_eq(c.state.winner,0)
	check_eq(c.history[-1].type,"game_over")


func test_autonomous_segment_replays_without_external_planning_state() -> void:
	for layered in [false,true]:
		var board := BoardLoader.load_id("stacked_gatehouse",terrain()) if layered else make_board()
		var c := make_game(board,[fig("thug",0,Vector2(2,2)),fig("thug",1,Vector2(15,14))],Dice.new(71))
		c.state.creature_db=db()
		c.state.reaction_side=-2
		if layered:
			for f in c.state.figures:
				f.surface_id="street"
		c.capture_frames=true
		c.start_game()
		var checkpoint := BattleSnapshot.capture(c)
		check(not checkpoint.is_empty())
		check(Bot.play_activation(c))
		check_eq(c.command_history.size(),2)
		if c.command_history.size()<2:
			continue
		check_eq(c.command_history[0]["key"],"activate")
		check_eq(c.command_history[1]["key"],"bot_resume")
		var result := BattleReplay.verify(checkpoint,db(),c.command_history,BattleRecord.pack(c.history))
		check(result.get("ok",false),str(result))
		check(c.replay_frames.size()>=2)
