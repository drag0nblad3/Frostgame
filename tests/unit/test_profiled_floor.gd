extends TestCase

func _board() -> Board:
	return BoardLoader.from_dict({"shared_profiled_climbing":true,"size":[20,20],"pieces":[{"kind":"sunken_ground","rect":[5,5,8,8],"level":-2},{"kind":"stone_stairs","rect":[7,1,4,4],"ramp":{"start":0,"end":-2,"axis":"y"}},{"kind":"stone_ramp","rect":[7,13,4,4],"ramp":{"start":-2,"end":0,"axis":"y"}},{"kind":"deep_water","rect":[8,8,2,2]}]},terrain())

func test_profile_height_and_cost_parity() -> void:
	var b:=_board()
	var l:=b.floor_geometry()
	check(l.errors.is_empty(),str(l.errors))
	for at: Vector2 in [Vector2(8,8),Vector2(8,3),Vector2(8,15),Vector2(4.5,8)]:
		check_eq(l.height(l.node("street",at)),b.ground_height_at(at))
	var grid:=LayeredGrid.new(l)
	var route:=LayeredReach.search(grid,l.node("street",Vector2(8,1)),5.0)
	check(route.can_reach(l.node("street",Vector2(8,5))))
	if route.can_reach(l.node("street",Vector2(8,5))):
		check(is_equal_approx(float(route.cost[l.node("street",Vector2(8,5))]),sqrt(20.0)))
	check_eq(TerrainTravel.cost(b,Vector2(4.5,8),Vector2(5,8),null,false,l.profiled_ground),4.5)
	check(not LayeredSight.clear(l,Vector3(5.5,-0.5,8),Vector3(2,1,8)))

func test_profiled_water_and_restore() -> void:
	var b:=_board()
	var f:=fig("thug",0,Vector2(9,9))
	f.surface_id="street"
	f.elevation=-2.0
	var c:=make_game(b,[f],Dice.new(7))
	check_eq(Swimming.figure_depth(f),2)
	var l:=b.floor_geometry()
	var grid:=LayeredGrid.new(l,f,c.state.figures)
	var a:=l.node("street",f.pos)
	var to:=l.node("street",Vector2(9.5,9))
	var r:=LayeredReach.search(grid,a,2.0)
	check_eq(r.cost.get(to,-1),1.0)
	var restored:=BattleSnapshotParts.make_board(BattleSnapshotParts.board_data(b))
	check_eq(restored.floor_geometry().height(restored.floor_geometry().node("street",f.pos)),-2.0)

func test_sunken_streets_preserves_real_ground() -> void:
	var s:=ScenarioLoader.load_id("sunken_streets",db(),terrain())
	check(not s.board.floor_layout.is_empty())
	check(not s.scenario_data.has("support_errors"),str(s.scenario_data.get("support_errors",[])))
	var l:=s.board.floor_geometry()
	check(l.errors.is_empty(),str(l.errors))
	check_eq(TreasureRules.token_height(s,s.treasures[0]),-2.0)
	for f in s.figures:
		check_eq(f.elevation,s.board.ground_height_at(f.pos))
