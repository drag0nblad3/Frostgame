extends TestCase


func test_spell_placement_replays_on_both_geometry_providers() -> void:
	for layered in [false,true]:
		var board := BoardLoader.load_id("stacked_gatehouse",terrain()) if layered else make_board()
		var c := make_game(board,[fig("wizard",0,Vector2(2,2)),fig("wizard",1,Vector2(15,14))],Dice.new(91))
		c.state.creature_db=db()
		c.state.spell_catalog=JsonFile.read("res://data/spells.json")
		c.state.spellbooks[0]={"teleport":10}
		c.state.active_id=1
		var f := c.state.active()
		f.surface_id="street" if layered else ""
		f.actions_left=2
		var checkpoint := BattleSnapshot.capture(c)
		check(not checkpoint.is_empty())
		var before := c.dice._rng.state
		var wrong: Variant=Vector2(3,3) if layered else Vector3i(6,6,0)
		check(not BattleSpellAction.execute(c,"place",{"spell":"teleport","at":wrong}))
		check_eq(c.dice._rng.state,before)
		check_eq(c.command_history.size(),0)
		check_eq(f.actions_left,2)
		var at: Variant=Vector3i(6,6,0) if layered else Vector2(3,3)
		check(BattleSpellAction.execute(c,"place",{"spell":"teleport","at":at}))
		check(not c.state.pending_cast.is_empty())
		if c.state.pending_cast.is_empty():
			continue
		check(c.finish_cast(0))
		check_eq(c.command_history.size(),2)
		var result := BattleReplay.verify(checkpoint,db(),c.command_history,BattleRecord.pack(c.history))
		check(result.get("ok",false),str(result))
