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
		check_eq(actor.actions_left,0,"Teleport ends the activation")
		check(actor.magic_exhausted)
		check_eq(layered.command_history.size(),1)
		check(actor.items.is_empty())


func test_teleportation_potion_exhausts_in_both_geometries() -> void:
	for layered in [false,true]:
		var board := BoardLoader.load_id("stacked_gatehouse",terrain()) if layered else make_board()
		var c := make_game(board,[fig("thug",0,Vector2(2,2)),fig("thug",1,Vector2(15,14))],Dice.new(71))
		c.state.active_id=1
		var actor := c.state.active()
		actor.surface_id="street" if layered else ""
		actor.actions_left=2
		actor.items.append({"potion":"teleportation"})
		var points := BattleEquipmentAction.points(c,"potion_teleportation",0)
		check(not points.is_empty())
		if points.is_empty():
			continue
		check(BattleEquipmentAction.execute(c,"potion_teleportation",{"at":points[0]}))
		check_eq(actor.actions_left,0,"Teleportation exhausts the figure")
		check(actor.magic_exhausted)
		check(actor.items.is_empty())
		check_eq(c.command_history.size(),1)


func test_expansion_potion_sources_preserve_consumption_contract() -> void:
	var c := make_game(make_board(),[fig("wizard",0,Vector2(2,2)),fig("thug",1,Vector2(15,14))],Dice.new(71))
	c.state.active_id=1
	var f := c.state.active()
	f.actions_left=2
	f.items.append({"gear":RedKingCampaignGear.POTION_STAFF,"potion":"strength"})
	check_eq(c._potions.source(f,"strength"),0)
	var rng := c.dice._rng.state
	check(c._potions._consume(f,"strength"))
	check_eq(c.dice._rng.state,rng)
	check_eq(f.items.size(),1)
	check(not f.items[0].has("potion"))
	f.items.append({"potion":"strength","enchanted":true})
	var expected := f.items.duplicate(true)
	var oracle := Dice.new(1)
	oracle._rng.state=c.dice._rng.state
	RedKingMaterials.use_potion(expected,1,oracle)
	check(c._potions._consume(f,"strength"))
	check_eq(f.items,expected)
	check_eq(c.dice._rng.state,oracle._rng.state)
	f.items.append({"potion":"strength"})
	var before := c.dice._rng.state
	var count := f.items.size()
	# A retained enchanted vial loses its enchantment, so either ordinary
	# source is consumed without a new roll.
	check(c._potions._consume(f,"strength"))
	check_eq(c.dice._rng.state,before)
	check_eq(f.items.size(),count-1)
