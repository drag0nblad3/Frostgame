extends TestCase


func test_independent_sight_movement_and_checkpoint() -> void:
	var b := make_board()
	var a := Vector2(10,10)
	var z := Vector2(20,10)
	b.set_boundaries([{"a":Vector2(15,0),"b":Vector2(15,36),"sight":true,"movement":false}])
	check(not LineOfSight.check(b,a,z).clear)
	check(MoveGrid.new(b).segment_cost(Vector2(14.5,10),Vector2(15,10))<INF)
	b.set_boundaries([{"a":Vector2(15,0),"b":Vector2(15,36),"movement":true,"allow_spells":["plane_walk"]}])
	check(LineOfSight.check(b,a,z).clear)
	check_eq(MoveGrid.new(b).segment_cost(Vector2(14.5,10),Vector2(15.5,10)),INF)
	var f := fig("wizard",0,a)
	f.spell_effects["plane_walk"]=true
	check(MoveGrid.new(b,f).segment_cost(Vector2(14.5,10),Vector2(15.5,10))<INF)
	var restored := BattleSnapshotParts.make_board(BattleSnapshotParts.board_data(b))
	check_eq(restored.boundaries,b.boundaries)
	check_eq(BattleBoundary.wrapped(Vector2(37,-1),b.size,true,true),Vector2(1,35))


func test_boundary_change_invalidates_static_paths() -> void:
	var b := make_board()
	var grid := MoveGrid.new(b)
	var a := Vector2i(29,20)
	var z := Vector2i(30,20)
	check(grid.step_cost(a,z)<INF)
	b.set_boundaries([{"a":Vector2(15,0),"b":Vector2(15,36),"movement":true}])
	check_eq(grid.step_cost(a,z),INF)
