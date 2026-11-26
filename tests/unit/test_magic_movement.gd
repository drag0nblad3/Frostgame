extends TestCase


func _game(rolls: Array) -> GameController:
	var c := make_game(make_board(), [fig("wizard", 0, Vector2(10, 10)), fig("thug", 0, Vector2(12, 10)), fig("thug", 1, Vector2(20, 10))], LoadedDice.new(rolls))
	c.state.spell_catalog = JsonFile.read("res://data/spells.json")
	c.state.spellbooks[0] = {"teleport": 10, "leap": 8, "transpose": 12, "push": 8}
	c.state.active_id = 1
	c.state.active().actions_left = 2
	return c


func test_leap_and_exhaustion() -> void:
	var c := _game([18])
	check(c._magic.start_move("leap", 2, Vector2(12, 18)))
	check(c.finish_cast(0))
	check_eq(c.state.figure(2).pos, Vector2(12, 18))
	check_eq(c.state.figure(2).action_limit(), 0)


func test_teleport() -> void:
	var c := _game([18])
	check(c._magic.start_at("teleport", Vector2(15, 15)))
	check(c.finish_cast(0))
	check_eq(c.state.active().pos, Vector2(15, 15))
	check_eq(c.state.active().actions_left, 0)


func test_transpose_resistance() -> void:
	var c := _game([18, 1])
	check(c._magic.start_swap(2, 3))
	check(c.finish_cast(0))
	check_eq(c.state.figure(2).pos, Vector2(20, 10))
	check_eq(c.state.figure(3).pos, Vector2(12, 10))
