extends TestCase


func test_consumable_command_replays_from_checkpoint() -> void:
	var c := make_game(make_board(),[fig("thug",0,Vector2(10,10)),fig("thug",1,Vector2(20,20))],Dice.new(51))
	c.state.creature_db=db()
	c.state.active_id=1
	var f := c.state.active()
	f.actions_left=2
	f.items.append({"potion":"strength"})
	var checkpoint := BattleSnapshot.capture(c)
	check(not checkpoint.is_empty())
	check(not BattleEquipmentAction.execute(c,"drink",{"id":"strength","target":999}))
	check_eq(c.command_history.size(),0)
	check(BattleEquipmentAction.execute(c,"drink",{"id":"strength"}))
	check_eq(f.actions_left,1)
	check_eq(f.effective_fight(),3)
	check(f.items.is_empty())
	check_eq(c.command_history.size(),1)
	var result := BattleReplay.verify(checkpoint,db(),c.command_history,BattleRecord.pack(c.history))
	check(result.get("ok",false),str(result))


func test_point_commands_reject_wrong_geometry_before_consumption() -> void:
	var flat := make_game(make_board(),[fig("thug",0,Vector2(10,10)),fig("thug",1,Vector2(20,20))],Dice.new(51))
	flat.state.active_id=1
	var f := flat.state.active()
	f.actions_left=2
	f.items.append({"potion":"teleportation"})
	var rng := flat.dice._rng.state
	check(not BattleEquipmentAction.execute(flat,"potion_teleportation",{"at":Vector3i(20,20,0)}))
	check_eq(f.actions_left,2)
	check_eq(f.items.size(),1)
	check_eq(flat.dice._rng.state,rng)
	check_eq(flat.command_history.size(),0)
	var board := BoardLoader.load_id("stacked_gatehouse",terrain())
	var layered := make_game(board,[fig("thug",0,Vector2(2,2)),fig("thug",1,Vector2(15,14))],Dice.new(51))
	layered.state.active_id=1
	var actor := layered.state.active()
	actor.surface_id="street"
	actor.actions_left=2
	actor.items.append({"potion":"teleportation"})
	check(not BattleEquipmentAction.execute(layered,"potion_teleportation",{"at":Vector2(3,3)}))
	check(not BattleEquipmentAction.execute(layered,"potion_teleportation",{"at":Vector3i(6,6,999)}))
	check_eq(actor.actions_left,2)
	check_eq(actor.items.size(),1)
	check_eq(layered.command_history.size(),0)
	var points := BattleEquipmentAction.points(layered,"potion_teleportation",0)
	check(not points.is_empty())
	if not points.is_empty():
		check(points[0] is Vector3i)
		check(BattleEquipmentAction.execute(layered,"potion_teleportation",{"at":points[0]}))
		check_eq(actor.actions_left,1)
		check(actor.items.is_empty())
