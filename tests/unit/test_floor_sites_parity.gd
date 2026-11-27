extends TestCase


func test_hut_discovery_is_not_triggered_by_overhead_figure() -> void:
	var b:=BoardLoader.from_dict({"size":[20,16],"floor_layout":{"surfaces":[{"id":"street","rect":[0,0,20,16],"level":0},{"id":"roof","rect":[2,2,16,12],"level":3}],"solids":[[2,2.8,2,16,0.2,12]]},"pieces":[{"kind":"haunted_floor","rect":[4,4,4,4]}]},terrain())
	var f:=fig("wizard",0,Vector2(6,6))
	f.surface_id="roof"
	f.elevation=3.0
	var c:=make_game(b,[f],LoadedDice.new([17]))
	c.state.scenario_special="haunted_houses"
	c.state.creature_db=db()
	check(not ScenarioSites.enter(c,f))
	check(c.state.discovered_huts.is_empty())
	f.surface_id="street"
	f.elevation=0.0
	check(ScenarioSites.enter(c,f))
	check_eq(c.state.discovered_huts.size(),1)
	check_eq(c.state.figures.size(),2)
	if c.state.figures.size()==2:
		check_eq(c.state.figures[1].surface_id,"street")
		check_eq(c.state.figures[1].def.id,"wraith")


func test_guardian_column_removes_physical_blocker() -> void:
	var b:=BoardLoader.from_dict({"id":"complex_temple","size":[16,16],"floor_layout":{"surfaces":[{"id":"street","rect":[0,0,16,16],"level":0},{"id":"roof","rect":[2,2,12,12],"level":4}],"solids":[[2,3.8,2,12,0.2,12]]},"pieces":[{"kind":"temple_column","rect":[7.5,7.5,1,1]}]},terrain())
	var f:=fig("wizard",0,Vector2(7,8))
	f.surface_id="street"
	var c:=make_game(b,[f],LoadedDice.new([20,1]))
	c.state.scenario_special="complex_temple"
	var token:=TreasureToken.new(0,Vector2(8,8))
	token.frozen=true
	ScenarioLoader.assign_token_support(c.state,token,"street")
	check_eq(token.surface_id,"street")
	c.state.treasures.append(token)
	check(ScenarioColumns.contact(b,f.pos,4.0)==null)
	check(ScenarioColumns.challenge(c,f))
	check(not token.frozen)
	check(b.floor_geometry().standable(b.floor_geometry().node("street",Vector2(8,8))))
	check_eq(f.treasure_id,token.id)
