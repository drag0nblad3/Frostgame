extends TestCase


func test_crumble_creates_opening() -> void:
	var c := make_game(make_board(), [fig("wizard", 0, Vector2(10, 10)), fig("thug", 1, Vector2(25, 25))], LoadedDice.new([18]))
	var k := TerrainKind.new()
	k.id = "wall"
	k.blocks_move = true
	k.blocks_los = true
	k.height = 3.0
	var piece := TerrainPiece.new(k, Rect2(13, 8, 1, 6))
	c.state.board.pieces.append(piece)
	c.state.board.invalidate_terrain()
	check(not c.state.board.can_stand(Vector2(13.5, 11), 0.5))
	c._magic.crumble.apply(piece)
	check_eq(c.state.board.pieces.size(), 2)
	check(c.state.board.can_stand(Vector2(13.5, 11), 0.5))
	check(LineOfSight.check(c.state.board, Vector2(10, 11), Vector2(16, 11)).clear)


func test_crumble_conjured_wall() -> void:
	var c := make_game(make_board(), [fig("wizard", 0, Vector2(10, 10)), fig("thug", 1, Vector2(25, 25))], Dice.new(1))
	c._magic.terrain.apply(c.state.figure(1), "wall", Vector2(15, 10), true)
	c._magic.crumble.apply(c.state.board.pieces[0])
	check(c.state.board.pieces.is_empty())
