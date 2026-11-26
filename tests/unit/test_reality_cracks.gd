extends TestCase


func _fixture() -> GameController:
	var packs := ContentProfile.registered().duplicate(true)
	packs["red_king"]["status"]="ready"
	var defs := FigureDb.load_files(FigureDb.FIGURES,FigureDb.WEAPONS,ContentProfile.new(["red_king"],packs))
	var s := ScenarioLoader.load_id("red_king_squatter",defs,terrain())
	s.scenario_data["reality_enabled"]=true
	return GameController.new(s,Dice.new(23))


func test_occurrence_and_single_use() -> void:
	check_eq(RealityCracks.threshold(1,2),20)
	check_eq(RealityCracks.threshold(2,2),18)
	check_eq(RealityCracks.threshold(2,3),19)
	var c := _fixture()
	c.state.turn=1
	RealityCracks.on_priority(c,[20,15])
	check(not c.state.scenario_data.get("reality_triggered",false))
	check(RealityCracks.apply(c,2))
	check_eq(c.state.board.boundaries.size(),1)
	RealityCracks.clear(c)
	check(c.state.board.boundaries.is_empty())
	check(not RealityCracks.apply(c,3))


func test_all_effects_dispatch_and_checkpoint() -> void:
	for effect in range(1,21):
		var c := _fixture()
		check(RealityCracks.apply(c,effect))
		check(c.state.scenario_data["reality_triggered"])
		var saved := BattleSnapshot.capture(c)
		check(not saved.is_empty())
		var restored := BattleSnapshot.rebuild(saved,c.state.creature_db)
		check(restored!=null)
		if restored!=null:
			check_eq(restored.state.scenario_data,c.state.scenario_data)
			check_eq(restored.state.board.boundaries,c.state.board.boundaries)
			check_eq(restored.state.board.low_gravity,c.state.board.low_gravity)


func test_sphere_cross_and_enneahedron() -> void:
	var c := _fixture()
	var b := c.state.board
	b.pieces.clear()
	b.invalidate_terrain()
	RealityCracks.apply(c,17)
	check(b.wrap_short_edges and b.wrap_long_edges)
	check(LineOfSight.check(b,Vector2(1,18),Vector2(35,18)).clear)
	check(not LineOfSight.check(b,Vector2(1,18),Vector2(10,18)).clear)
	check_eq(RealityCrackGeometry.sight_distance(b,Vector2(1,18),Vector2(35,18)),2.0)
	check(not ScenarioObjectives.exit_allowed(c.state,Vector2(0.5,18)))
	check(BoardTopology.destinations(b,Vector2i(1,20)).has(Vector2i(71,20)))
	RealityCracks.clear(c)
	check(not b.wrap_short_edges and not b.wrap_long_edges)
	c.state.scenario_data.erase("reality_triggered")
	RealityCracks.apply(c,18)
	b.reality_cross=0
	check_eq(RealityCrackGeometry.cross_relation(b,Vector2(24,8),Vector2(8,24)),1)
	check(LineOfSight.check(b,Vector2(24,8),Vector2(8,24)).clear)
	check(not LineOfSight.check(b,Vector2(8,8),Vector2(24,8)).clear)
	RealityCracks.clear(c)
	c.state.scenario_data.erase("reality_triggered")
	RealityCracks.apply(c,20)
	check_eq(b.boundaries.size(),4)
	check(BattleBoundary.blocks_end(b.boundaries,Vector2(12,6)))
	check(not BattleBoundary.blocks_segment(b.boundaries,Vector2(10,6),Vector2(14,6),"movement"))
	check(BattleBoundary.blocks_segment(b.boundaries,Vector2(10,6),Vector2(14,6),"sight"))
