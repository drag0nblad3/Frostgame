extends TestCase


func test_global_words() -> void:
	var c := make_game(make_board(), [fig("wizard", 0, Vector2(10, 10)), fig("wizard", 1, Vector2(20, 20))], LoadedDice.new([18]))
	c.state.spell_catalog = JsonFile.read("res://data/spells.json")
	c.state.spellbooks[0] = {"power_word": 14}
	c.state.active_id = 1
	c.state.active().actions_left = 2
	var options := c._magic.counter_options("power_word")
	for i in options.size():
		if options[i]["chosen"] == "heal":
			check(c._magic.start_counter("power_word", i))
			check(c.finish_cast(0))
			break
	check_eq(WordMagic.modifier(c.state, "heal"), 3)
	check(WordMagic.options(c.state, c.state.active(), "power_word").is_empty())
	WordMagic.apply(c.state, c.state.figure(2), "draining_word", "heal")
	check_eq(WordMagic.modifier(c.state, "heal"), 0)


func test_strike_dead_soldier_resistance() -> void:
	var c := make_game(make_board(), [fig("wizard", 1, Vector2(10, 10)), fig("thug", 0, Vector2(14, 10))], LoadedDice.new([18, 15]))
	c.state.spell_catalog = JsonFile.read("res://data/spells.json")
	c.state.spellbooks[1] = {"strike_dead": 18}
	c.state.reaction_side = 0
	c.state.active_id = 1
	c.state.active().actions_left = 2
	check(c.start_cast("strike_dead", 2))
	check_eq(c.state.active().health, 13)
	check(c.finish_cast(0))
	check(c.awaiting_reaction())
	check(c._magic.resistance.answer(4))
	check_eq(c.state.figure(2).health, 6)
