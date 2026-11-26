extends TestCase


func test_rune_does_not_trigger_at_placement() -> void:
	var c := make_game(make_board(), [fig("wizard", 0, Vector2(10, 10)), fig("thug", 1, Vector2(13, 10))], LoadedDice.new([18, 1, 18, 1]))
	var owner := c.state.figure(1)
	var enemy := c.state.figure(2)
	c._magic.terrain.apply(owner, "explosive_rune", Vector2(12, 10), false)
	check_eq(c.state.board.pieces.size(), 1)
	check_eq(enemy.health, 10)
	check(c._magic.terrain.triggered(owner, Vector2(12, 10)).is_empty())
	check_eq(c._magic.terrain.triggered(enemy, Vector2(13, 10)).size(), 1)
	c._magic.terrain.trigger_landing(enemy)
	check_eq(c.state.board.pieces.size(), 0)
	check(enemy.health < 10)


func test_planar_tear_damage() -> void:
	var c := make_game(make_board(), [fig("wizard", 0, Vector2(10, 10)), fig("imp", -1, Vector2(14, 10)), fig("thug", 1, Vector2(15, 10))], LoadedDice.new([1, 1]))
	c._magic.terrain.apply(c.state.figure(1), "planar_tear", Vector2(14, 10), false, 14)
	check(c.state.figure(2).out_of_action)
	check_eq(c.state.figure(3).health, 8)
