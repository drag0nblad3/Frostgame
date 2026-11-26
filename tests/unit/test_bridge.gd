extends TestCase


func test_bridge_surface_and_expiry() -> void:
	var c := make_game(make_board(), [fig("wizard", 0, Vector2(10, 10)), fig("thug", 1, Vector2(25, 25))], LoadedDice.new([1]))
	var k := TerrainKind.new()
	k.walkable_top = true
	k.height = 3.0
	var p := TerrainPiece.new(k, Rect2(17.9, 9, 2, 2))
	c.state.board.pieces.append(p)
	c._magic.terrain.apply(c.state.figure(1), "bridge", Vector2(15, 10), false)
	check_eq(c.state.board.height_at(Vector2(15, 10)), 1.5)
	var grid := MoveGrid.new(c.state.board, c.state.figure(1), c.state.figures)
	check(grid.segment_cost(Vector2(14, 10), Vector2(14.5, 10)) < 1.0)
	c.state.turn = 1
	c._magic.terrain.expire()
	check_eq(c.state.board.height_at(Vector2(15, 10)), 0.0)
