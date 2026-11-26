extends TestCase


func _game(rolls: Array) -> GameController:
	var c := make_game(make_board(), [fig("wizard", 0, Vector2(10, 10)), fig("thug", 0, Vector2(20, 10)), fig("wizard", 1, Vector2(30, 30))], LoadedDice.new(rolls))
	c.state.spell_catalog = JsonFile.read("res://data/spells.json")
	c.state.spellbooks[0] = {"fast_act": 8, "time_store": 14, "time_walk": 14}
	c.start_game()
	return c


func test_fast_act_early_activation() -> void:
	var c := _game([18, 2, 18])
	check(c.activate(1))
	check(c.start_cast("fast_act", 2))
	check(c.finish_cast(0))
	c.end_activation()
	check_eq(c.activatable()[0].id, 2)
	check(c.activate(2))
	c.end_activation()
	check_eq(c.state.current_side(), 1)


func test_stored_action() -> void:
	var c := _game([18, 2, 18])
	check(c.activate(1))
	check(c.start_cast("time_store", 1))
	check(c.finish_cast(0))
	check_eq(c.state.active().actions_left, 0)
	check(c.state.active().spell_effects.has("time_store"))
	check(not c.use_stored_action())
	c.state.turn += 1
	c.state.active().actions_left = 2
	c.state.active().acted = false
	c.state.active().non_moves = 0
	check(c.use_stored_action())
	check_eq(c.state.active().actions_left, 3)
	c._spend(c.state.active())
	check(c.can_act())
	c._spend(c.state.active())
	check(not c.can_act())
	check_eq(c.state.active().actions_left, 1)


func test_time_walk_extra_phases() -> void:
	var c := _game([18, 2, 18])
	check(c.activate(1))
	check(c.start_cast("time_walk", 1))
	check(c.finish_cast(0))
	c.end_activation()
	check(c.activate(3))
	c.end_activation()
	check_eq(c.state.phase, Phase.APPRENTICE)
	check(c.activate(1))
	check_eq(c.state.active().actions_left, 1)
	c.end_activation()
	check_eq(c.state.phase, Phase.SOLDIER)
	check(c.activate(1))
	check_eq(c.state.active().actions_left, 1)
