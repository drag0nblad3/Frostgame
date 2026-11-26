extends TestCase


func _game(rolls: Array) -> GameController:
	var c := make_game(make_board(), [fig("wizard", 0, Vector2(10, 10)), fig("thug", 1, Vector2(14, 10))], LoadedDice.new(rolls))
	c.state.spell_catalog = JsonFile.read("res://data/spells.json")
	c.state.spellbooks[0] = {"dispel": 12, "spell_eater": 12}
	c.state.active_id = 1
	c.state.active().actions_left = 2
	return c


func test_dispel_single_effect() -> void:
	var c := _game([18])
	var t := c.state.figure(2)
	t.spell_effects = {"shield": true, "strength": true}
	check_eq(c._magic.counter_options("dispel").size(), 2)
	check(c._magic.start_counter("dispel", 0))
	check(c.finish_cast(0))
	check_eq(t.spell_effects.size(), 1)
	check_eq(c.state.active().health, 14)


func test_spell_eater_health_and_storm() -> void:
	var c := _game([18])
	c.state.storm_penalty = 2
	check(c._magic.start_counter("spell_eater", 0))
	check(c.finish_cast(0))
	check_eq(c.state.storm_penalty, 1)
	check_eq(c.state.active().health, 13)
