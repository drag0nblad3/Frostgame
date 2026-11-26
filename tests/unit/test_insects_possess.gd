extends TestCase


func test_cloud_follows_host() -> void:
	var c := make_game(make_board(), [fig("wizard", 0, Vector2(10, 10)), fig("thug", 1, Vector2(14, 10)), fig("thug", 0, Vector2(15, 10)), fig("skeleton", -1, Vector2(14, 11))], LoadedDice.new([18]))
	c.state.spell_catalog = JsonFile.read("res://data/spells.json")
	c.state.spellbooks[0] = {"plague_of_insects": 10}
	c.state.active_id = 1
	c.state.active().actions_left = 2
	check(c.start_cast("plague_of_insects", 2))
	check(c.finish_cast(0))
	check_eq(c.state.figure(2).effective_fight(), 0)
	check_eq(c.state.figure(3).effective_fight(), 0)
	check(not c.state.figure(4).affected_by_insects())
	c.state.figure(2).pos = Vector2(22, 10)
	check_eq(c.state.figure(3).effective_fight(), 2)


func test_possess_stats_and_demon() -> void:
	var c := make_game(make_board(), [fig("wizard", 0, Vector2(10, 10)), fig("thug", 0, Vector2(14, 10)), fig("thug", 1, Vector2(25, 25))], LoadedDice.new([18]))
	c.state.spell_catalog = JsonFile.read("res://data/spells.json")
	c.state.spellbooks[0] = {"possess": 12}
	c.state.active_id = 1
	c.state.active().actions_left = 2
	var t := c.state.figure(2)
	check(c.start_cast("possess", 2))
	check(c.finish_cast(0))
	check_eq(t.effective_fight(), 4)
	check_eq(t.effective_armour(), 11)
	check_eq(t.effective_will(), -3)
	check(t.is_demon())
	t.spell_effects.erase("possess")
	check(not t.is_demon())
