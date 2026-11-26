extends TestCase


func _game(rolls: Array) -> GameController:
	var c := make_game(make_board(), [fig("wizard", 1, Vector2(10, 10)), fig("wizard", 0, Vector2(14, 10))], LoadedDice.new(rolls))
	c.state.spell_catalog = JsonFile.read("res://data/spells.json")
	c.state.spellbooks[1] = {"petrify": 10}
	c.state.reaction_side = 0
	c.state.active_id = 1
	c.state.active().actions_left = 2
	return c


func test_human_resist_empowerment() -> void:
	var c := _game([18, 12])
	check(c.start_cast("petrify", 2))
	check(c.finish_cast(0))
	check(c.awaiting_reaction())
	var p := c.state.pending_resistance
	var needed := int(p["tn"]) - int(p["raw"]) - int(p["mod"])
	check(needed > 0)
	check(c._magic.resistance.answer(needed))
	check(not c.awaiting_reaction())
	check(not c.state.figure(2).petrified_skip)
	check_eq(c.state.figure(2).health, 14 - needed)


func test_natural_one_no_empowerment() -> void:
	var c := _game([18, 1])
	check(c.start_cast("petrify", 2))
	check(c.finish_cast(0))
	check(not c.awaiting_reaction())
	check(c.state.figure(2).petrified_skip)
