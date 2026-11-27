extends TestCase


func test_eye_sight_and_host_removal() -> void:
	var c := make_game(make_board(), [fig("wizard", 0, Vector2(10, 10)), fig("thug", 1, Vector2(18, 10))], Dice.new(1))
	var k := TerrainKind.new()
	k.id = "wall"
	k.name = "Wall"
	k.height = 3.0
	k.blocks_move = true
	k.blocks_los = true
	var p := TerrainPiece.new(k, Rect2(13, 8, 1, 4))
	c.state.board.pieces.append(p)
	var f := c.state.figure(1)
	var at := Vector2(14.15, 10)
	check(not WizardEye.visible(c.state.board, f, Vector2(18, 10)))
	c._magic.eye.create(f, {"piece": p, "at": at, "direction": Vector2.RIGHT})
	check(WizardEye.visible(c.state.board, f, Vector2(18, 10)))
	check_eq(WizardEye.origin(c.state.board, f, Vector2(18, 10)), at)
	c._magic.terrain.remove(p)
	check(WizardEye.marker(c.state.board, f) == null)
	check(c.state.board.pieces.is_empty())


func test_tiger_eye_ring_penalty() -> void:
	var f := fig("wizard",0,Vector2(10,10))
	var c := make_game(make_board(),[f],LoadedDice.new([1]))
	f.items.append({"gear":TigerEye.ITEM,"gear_info":RedKingRewards.catalog()[TigerEye.ITEM]})
	check(TigerEye.active(f))
	var hp := f.health
	TigerEye.test_use(c,f)
	check_eq(f.health,hp-3)
