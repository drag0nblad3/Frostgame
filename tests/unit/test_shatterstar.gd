extends TestCase


func test_two_declared_targets_one_action() -> void:
	var c := make_game(make_board(), [fig("wizard", 0, Vector2(10, 10)), fig("thug", 0, Vector2(13, 10)), fig("thug", 1, Vector2(25, 25))], LoadedDice.new([18, 19]))
	c.state.spell_catalog = JsonFile.read("res://data/spells.json")
	c.state.spellbooks[0] = {"fleet_feet": 10}
	c.state.active_id = 1
	var f := c.state.active()
	f.actions_left = 2
	f.items.append({"potion": "shatterstar"})
	check(c._potions.drink("shatterstar"))
	check_eq(f.actions_left, 1)
	check(not c.start_cast("fleet_feet", 1))
	check(c.state.pending_cast.is_empty())
	check_eq(f.actions_left, 1)
	check(c.start_cast("fleet_feet", 2))
	check_eq(c.state.pending_cast["raw"], 18)
	check(c.finish_cast(0))
	check(f.spell_effects.has("fleet_feet"))
	check_eq(c.state.pending_cast["raw"], 19)
	check(c.finish_cast(0))
	check(c.state.figure(2).spell_effects.has("fleet_feet"))
	check_eq(f.actions_left, 0)
	check_eq(f.non_moves, 1)
