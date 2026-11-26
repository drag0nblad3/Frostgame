extends TestCase


func test_mud_changes_cached_movement() -> void:
	var c := make_game(make_board(), [fig("wizard", 0, Vector2(10, 10)), fig("thug", 1, Vector2(25, 25))], LoadedDice.new([18]))
	c.state.spell_catalog = JsonFile.read("res://data/spells.json")
	c.state.spellbooks[0] = {"mud": 10}
	c.state.active_id = 1
	c.state.active().actions_left = 2
	check_eq(c.state.board.move_mult_at(Vector2(15, 10)), 1.0)
	check(c._magic.start_at("mud", Vector2(15, 10)))
	check(c.finish_cast(0))
	check_eq(c.state.board.move_mult_at(Vector2(15, 10)), 2.0)
	check_eq(c.state.board.move_mult_at(Vector2(17.5, 12.5)), 1.0)


func test_wall_expiry() -> void:
	var c := make_game(make_board(), [fig("wizard", 0, Vector2(10, 10)), fig("thug", 1, Vector2(25, 25))], LoadedDice.new([1]))
	c.state.turn = 1
	c._magic.terrain.apply(c.state.figure(1), "wall", Vector2(15, 10), true)
	check_eq(c.state.board.height_at(Vector2(15, 10)), 3.0)
	check(not LineOfSight.check(c.state.board, Vector2(10, 10), Vector2(20, 10)).clear)
	c.state.turn = 2
	c._magic.terrain.expire()
	check_eq(c.state.board.height_at(Vector2(15, 10)), 0.0)
	check(LineOfSight.check(c.state.board, Vector2(10, 10), Vector2(20, 10)).clear)
