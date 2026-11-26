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
	check(not board.static_step_cache.is_empty())
	board.invalidate_terrain()
	check(board.static_step_cache.is_empty())
	check(board._height_cache.is_empty())
