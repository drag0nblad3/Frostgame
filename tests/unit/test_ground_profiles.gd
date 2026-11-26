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
	check(not LineOfSight.check(b,Vector2(5.5,8),Vector2(4.5,8)).clear)
	check(LineOfSight.check(b,Vector2(6,7),Vector2(11,10)).clear)
