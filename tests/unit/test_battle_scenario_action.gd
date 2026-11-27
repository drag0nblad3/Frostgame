extends TestCase


func test_ring_switch_records_and_replays_on_both_geometries() -> void:
	for layered in [false,true]:
		var board := BoardLoader.load_id("stacked_gatehouse",terrain()) if layered else make_board()
		var c := make_game(board,[fig("thug",0,Vector2(2,2)),fig("thug",1,Vector2(15,14))],Dice.new(55))
		c.state.creature_db=db()
		c.state.scenario_special=RedKingRingworld.ID
		RedKingRingworld.setup(c.state)
		c.state.active_id=1
		var f := c.state.active()
		f.surface_id="street" if layered else ""
		f.actions_left=2
		var checkpoint := BattleSnapshot.capture(c)
		check(not checkpoint.is_empty())
		var rng := c.dice._rng.state
		check(not BattleScenarioAction.execute(c,"nonexistent"))
		check(not BattleScenarioAction.execute(c,"shift_ruin",{"piece":999,"at":Vector2(1,1)}))
		check_eq(c.command_history.size(),0)
		check_eq(c.dice._rng.state,rng)
		check(BattleScenarioAction.execute(c,"ring_switch"))
		check_eq(f.ring_side,1)
		check_eq(f.actions_left,1)
		check_eq(f.moves_taken,1)
		check_eq(c.command_history.size(),1)
		var replay := BattleReplay.verify(checkpoint,db(),c.command_history,BattleRecord.pack(c.history))
		check(replay.get("ok",false),str(replay))


func test_scenario_commands_do_not_leak_into_ordinary_battles() -> void:
	var c := make_game(make_board(),[fig("thug",0,Vector2(2,2)),fig("thug",1,Vector2(15,14))],Dice.new(55))
	c.state.active_id=1
	c.state.active().actions_left=2
	var rng := c.dice._rng.state
	for key in ["ring_switch","ring_escape","reality_exit","exchange","sinkhole","veil","memory"]:
		check(not BattleScenarioAction.execute(c,key),key)
	check_eq(c.state.active().actions_left,2)
	check_eq(c.state.active().ring_side,0)
	check_eq(c.dice._rng.state,rng)
	check_eq(c.command_history.size(),0)
