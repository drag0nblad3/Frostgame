extends TestCase


func _board() -> Board:
	return BoardLoader.from_dict({"size":[20,20],"pieces":[
		{"kind":"sunken_ground","rect":[5,5,8,8],"level":-2.0},
		{"kind":"stone_stairs","rect":[7,1,4,4],"ramp":{"start":0.0,"end":-2.0,"axis":"y"}},
		{"kind":"stone_ramp","rect":[7,13,4,4],"ramp":{"start":-2.0,"end":0.0,"axis":"y"}}
	]},terrain())


func test_negative_height_and_checkpoint() -> void:
	var b := _board()
	check_eq(b.height_at(Vector2(8,8)),-2.0)
	check_eq(b.height_at(Vector2(8,3)),-1.0)
	check_eq(b.height_at(Vector2(8,15)),-1.0)
	var saved := BattleSnapshotParts.make_board(BattleSnapshotParts.board_data(b))
	check(saved.has_ground_profiles and saved.has_ramps)
	check_eq(saved.height_at(Vector2(8,8)),-2.0)


func test_stairs_and_ramp_cost() -> void:
	var b := _board()
	var grid := MoveGrid.new(b)
	var total := 0.0
	for y in range(2,10):
		total += grid.step_cost(Vector2i(16,y),Vector2i(16,y+1))
	check(is_equal_approx(total,sqrt(20.0)))
	check(is_equal_approx(grid.segment_cost(Vector2(8,13),Vector2(8,13.5)),sqrt(0.3125)))
	check_eq(grid.segment_cost(Vector2(4.5,8),Vector2(5,8)),4.5)
	check(MovePlanner.reach(grid,Vector2(8,1),5.0).can_reach(MovePlanner.node_at(Vector2(8,5))))


func test_banks_block_sight() -> void:
	var b := _board()
	check(not LineOfSight.check(b,Vector2(5.5,8),Vector2(2,8)).clear)
	check(LineOfSight.check(b,Vector2(6,7),Vector2(11,10)).clear)


func test_surface_picking_and_mesh() -> void:
	var b := _board()
	check_eq(SurfacePicker.pick(b,Vector3(8,10,3),Vector3.DOWN),Vector2(8,3))
	check_eq(SurfacePicker.pick(b,Vector3(8,10,8),Vector3.DOWN),Vector2(8,8))
	var mesh := GroundMesh.build(b)
	check(mesh.get_surface_count()>0)
	check(mesh.get_aabb().position.y < -1.9)


func test_sunken_streets_deployment() -> void:
	var s := ScenarioLoader.load_id("sunken_streets",db(),terrain())
	check(s.board.has_ground_profiles)
	check_eq(s.board.height_at(s.treasures[0].pos),-2.0)
	for unit in s.figures:
		check(s.board.can_stand(unit.pos,Figure.BASE_RADIUS))
		check_eq(unit.elevation,s.board.height_at(unit.pos))
