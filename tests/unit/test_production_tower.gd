extends TestCase


func test_production_tower_preserves_scenario_and_legal_paths() -> void:
	var s:=ScenarioLoader.load_id("silent_tower",db(),terrain())
	check(s.random_encounters)
	check(s.forced_combat)
	check_eq(s.treasures.size(),5)
	check_eq(s.treasures[0].surface_id,"tower_roof")
	check(not s.scenario_data.has("deployment_error"),str(s.scenario_data.get("deployment_error","")))
	var layout:=s.board.floor_geometry()
	check(layout.errors.is_empty(),str(layout.errors))
	var start:=layout.node("street",Vector2(18,9))
	var summit:=layout.node("tower_roof",Vector2(18,18))
	check_eq(layout.height(summit),10.0)
	check(LayeredReach.search(LayeredGrid.new(layout),start,100.0).can_reach(summit))
	check(not LineOfSight.floor_ray(s.board,layout,Vector3(18,1,18),Vector3(18,11,18)))
	for t in s.treasures:
		check(layout.standable(layout.node(t.surface_id,t.pos),TreasureRules.TOKEN_RADIUS,0.5))


func test_architecture_destruction_opens_doorway() -> void:
	var b:=BoardLoader.from_dict({"size":[20,16],"floor_layout":{"surfaces":[{"id":"street","rect":[0,0,20,16],"level":0}]},"pieces":[{"kind":"ruin","rect":[9,4,2,6]}]},terrain())
	var f:=fig("wizard",0,Vector2(5,7))
	f.surface_id="street"
	var c:=make_game(b,[f],LoadedDice.new([20]))
	var p:=b.pieces[0]
	check(not b.floor_geometry().standable(b.floor_geometry().node("street",Vector2(10,7))))
	c._magic.crumble.apply(p)
	check_eq(b.pieces.size(),2)
	check(b.floor_geometry().errors.is_empty(),str(b.floor_geometry().errors))
	check(b.floor_geometry().standable(b.floor_geometry().node("street",Vector2(10,7))))
	check(LineOfSight.floor_ray(b,b.floor_geometry(),Vector3(5,1,7),Vector3(14,1,7),f))
