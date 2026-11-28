extends TestCase


func test_incremental_terrain_keeps_unaffected_meshes() -> void:
	var terrain := TerrainDb.load_file()
	var board := BoardLoader.load_id("frozen_ruins",terrain)
	var view := BoardView.new()
	view.build(board)
	var original := board.pieces[0]
	var node: Node3D=view._pieces[original]["node"]
	var city := view._scenery
	var decoration := view._decoration
	var removed: TerrainPiece=board.pieces.pop_back()
	board.invalidate_terrain()
	view.sync_terrain(board)
	check_eq(view._scenery,city)
	check_eq(view._pieces[original]["node"],node)
	check(not view._pieces.has(removed))
	check(view._decoration!=decoration)
	view.free()


func test_d20_closed_form_matches_enumeration() -> void:
	for diff in range(-25,26):
		var wins := 0
		for a in range(1,21):
			for b in range(1,21):
				if a+diff>b:
					wins+=1
		check(is_equal_approx(Dice.chance_win(diff,0),float(wins)/400.0))


func test_static_step_cache_clears_on_terrain_change() -> void:
	var board := BoardLoader.load_id("sunken_streets",TerrainDb.load_file())
	var grid := MoveGrid.new(board)
	var a := Vector2i(10,10)
	var b := Vector2i(11,10)
	var first := grid.step_cost(a,b)
	check_eq(grid.step_cost(a,b),first)
	var cache := board.static_step_cache
	check(cache.count(-1.0) < cache.size(), "step cost cached")
	board.height_at(Vector2(5,5))
	board.invalidate_terrain()
	check_eq(board.static_step_cache.count(-1.0), board.static_step_cache.size())
	var heights := board._height_cache
	for h in heights:
		check(is_nan(h), "height cache cleared")
		break


func test_restarting_same_map_reuses_city() -> void:
	var terrain := TerrainDb.load_file()
	var view := BoardView.new()
	var board := BoardLoader.load_id("frozen_ruins",terrain)
	view.build(board)
	var city := view._scenery
	view.build(BoardLoader.load_id("frozen_ruins",terrain))
	check_eq(view._scenery,city)
	check(view.scenery_ready())
	view.build(BoardLoader.load_id("underground_library",terrain))
	check(view._scenery!=city)
	check_eq(view._scenery.get_child_count(),4)
	check(view.scenery_ready())
	view.free()


func test_standard_ruins_use_real_ground_profiles() -> void:
	var board:=BoardLoader.load_id("frozen_ruins",TerrainDb.load_file())
	check(board.has_ground_profiles and board.has_ramps)
	check_eq(board.ground_height_at(Vector2(15.5,11.5)),1.0)
	check_eq(board.ground_height_at(Vector2(20.5,24.0)),-1.0)
	check(is_equal_approx(board.ground_height_at(Vector2(11.75,11.5)),0.5))
	var cost:=TerrainTravel.cost(board,Vector2(10.5,11.5),Vector2(13,11.5))
	check(is_equal_approx(cost,sqrt(2.5*2.5+1.0)))
	for at: Vector2 in [Vector2(18,14),Vector2(12,14),Vector2(24,14),Vector2(12,23),Vector2(24,23)]:
		check(board.can_stand(at,Figure.BASE_RADIUS),"treasure approach")
	var before:=board.pieces.size()
	var art:=Node3D.new()
	BattlefieldDetail.build(art,board,"treasure_skirmish")
	check(art.get_child_count()>0)
	check_eq(board.pieces.size(),before)
	check_eq(board.ground_height_at(Vector2(15.5,11.5)),1.0)
	art.free()


func test_mindscape_stays_terrain_free() -> void:
	var board:=BoardLoader.load_id("red_king_mind",TerrainDb.load_file())
	var art:=Node3D.new()
	BattlefieldDetail.build(art,board,"red_king_mind")
	check_eq(board.pieces.size(),0)
	check_eq(art.get_child_count(),0)
	art.free()


func test_static_open_cache_is_shared_and_invalidated() -> void:
	var board:=BoardLoader.load_id("frozen_ruins",TerrainDb.load_file())
	var node:=Vector2i(4,4)
	var a:=MoveGrid.new(board)
	var b:=MoveGrid.new(board)
	var answer:=a.open(node)
	var before:=MoveGrid.evaluations
	check_eq(b.open(node),answer)
	check_eq(MoveGrid.evaluations,before)
	board.invalidate_terrain()
	check_eq(b.open(node),answer)
	check_eq(MoveGrid.evaluations,before+1)
