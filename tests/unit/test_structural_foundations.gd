extends TestCase


func test_terrain_assemblies_expand_without_mutating_templates() -> void:
	var source := {"kits":{"hut":[{"kind":"wall","rect":[1,2,3,0.5]}]},"assemblies":[{"kit":"hut","origin":[10,5]},{"kit":"hut","origin":[20,10]}],"pieces":[{"kind":"rubble","rect":[2,2,1,1]}]}
	var expanded := TerrainAssembly.pieces(source)
	check_eq(expanded.size(),3)
	check_eq(expanded[0]["rect"],[11,7,3,0.5])
	check_eq(expanded[1]["rect"],[21,12,3,0.5])
	check_eq(source["kits"]["hut"][0]["rect"],[1,2,3,0.5])
	var board := BoardLoader.from_dict(source,terrain())
	check_eq(board.pieces.size(),3)


func test_haunted_houses_assembly_count() -> void:
	var board := BoardLoader.load_id("haunted_houses",terrain())
	check_eq(board.pieces.size(),54)
	var huts := 0
	for p in board.pieces:
		if p.kind.id=="haunted_floor":
			huts+=1
	check_eq(huts,5)


func test_shared_space_uses_elevation() -> void:
	var a := fig("wizard",0,Vector2(10,10))
	var b := fig("thug",1,Vector2(13,10))
	b.elevation=4.0
	check_eq(BattleSpace.edge_distance(a,b),4.0)
	check_eq(Shooting.distance(a,b),4.0)


func test_presentation_beats_and_pacing() -> void:
	var fight := GameEvent.new("fight")
	var hit := GameEvent.new("damage")
	var poison := GameEvent.new("poison")
	check_eq(BattlePresentation.beat(fight),"action")
	check_eq(BattlePresentation.beat(hit),"consequence")
	check_eq(BattlePresentation.hold(hit,poison,false),0.45)
	check_eq(BattlePresentation.hold(hit,null,true),1.3)


func test_audit_records_only_accepted_transactions() -> void:
	var c := make_game(make_board(),[fig("wizard",0,Vector2(10,10)),fig("thug",1,Vector2(13,10))],Dice.new(5))
	check(not BattleRecord.run(c,"reject",{},func() -> bool: return false))
	check_eq(c.command_history.size(),0)
	var before := c.dice._rng.state
	check(BattleRecord.run(c,"example",{"target":2},func() -> bool:
		c.emit("example",{"roll":c.dice.d20()})
		return true))
	check_eq(c.command_history.size(),1)
	check_eq(c.command_history[0]["rng_before"],before)
	check_eq(c.command_history[0]["event_end"],1)
	var records := BattleRecord.pack(c.history)
	var restored := BattleRecord.unpack(records)
	check_eq(restored[0].data,c.history[0].data)
	restored[0].data["roll"]=0
	check(c.history[0].data["roll"]>0)


func test_expedition_stage_derived_from_existing_data() -> void:
	check_eq(ExpeditionStage.current({},false,false),"Create warband")
	check_eq(ExpeditionStage.current({"name":"Test"},true,false),"Expedition in progress")
	check_eq(ExpeditionStage.current({"name":"Test"},false,false),"Recovery & preparation")
	check_eq(ExpeditionStage.current({"name":"Test"},false,true),"Ready for expedition")


func test_rotated_assembly_keeps_entrance_and_ramp_aligned() -> void:
	var source := {"kits":{"stair":[{"kind":"wall","rect":[1,2,3,4],"entrance":"north","ramp":{"axis":"y","start":0,"end":2}}]},"assemblies":[{"kit":"stair","origin":[10,10],"quarter_turns":1}]}
	var piece: Dictionary=TerrainAssembly.pieces(source)[0]
	check_eq(piece["rect"],[4.0,11.0,4.0,3.0])
	check_eq(piece["entrance"],"east")
	check_eq(piece["ramp"],{"axis":"x","start":2,"end":0.0})
	check_eq(source["kits"]["stair"][0]["ramp"]["axis"],"y")


func test_replay_verifies_real_activation_and_rejects_divergence() -> void:
	var c := make_game(make_board(),[fig("wizard",0,Vector2(10,10)),fig("wizard",1,Vector2(20,20))],Dice.new(4242))
	c.state.creature_db=db()
	c.start_game()
	var checkpoint := BattleSnapshot.capture(c)
	check(not checkpoint.is_empty())
	var options := c.activatable()
	check(not options.is_empty())
	if checkpoint.is_empty() or options.is_empty():
		return
	check(c.activate(options[0].id))
	c.end_activation()
	var events := BattleRecord.pack(c.history)
	var records := c.command_history.duplicate(true)
	var result := BattleReplay.verify(checkpoint,db(),records,events)
	check(result.get("ok",false),str(result))
	if not records.is_empty():
		records[0]["rng_after"]=int(records[0]["rng_after"])+1
		check(not BattleReplay.verify(checkpoint,db(),records,events).get("ok",true))
