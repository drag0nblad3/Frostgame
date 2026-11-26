extends TestCase


func test_plane_walk_crosses_wall() -> void:
	var c := make_game(make_board(), [fig("wizard", 0, Vector2(10, 10)), fig("archer", 1, Vector2(20, 10))], LoadedDice.new([18]))
	var k := TerrainKind.new()
	k.blocks_move = true
	k.blocks_los = true
	k.height = 3.0
	c.state.board.pieces.append(TerrainPiece.new(k, Rect2(12, 6, 1, 8)))
	c.state.board.invalidate_terrain()
	c.state.spell_catalog = JsonFile.read("res://data/spells.json")
	c.state.spellbooks[0] = {"plane_walk": 10}
	c.state.active_id = 1
	var f := c.state.active()
	f.actions_left = 2
	check(c.start_cast("plane_walk", 1))
	check(c.finish_cast(0))
	check(not c.can_act())
	check(c.move_to(MovePlanner.node_at(Vector2(15, 10))))
	check_eq(f.pos, Vector2(15, 10))
	check(not IllusionRules.visible_to(c.state.figures, c.state.figure(2), f))
	check_eq(PlaneWalk.penalty(f, c.state.turn + 1), -5)
	c._magic.on_end_turn()
	check(not f.spell_effects.has("plane_walk"))
