extends TestCase


func test_null_clears_magic_without_unsummoning() -> void:
	var c := make_game(make_board(), [fig("wizard", 0, Vector2(10, 10)), fig("imp", 0, Vector2(14, 10)), fig("thug", 1, Vector2(25, 25))], LoadedDice.new([1]))
	var w := c.state.figure(1)
	var imp := c.state.figure(2)
	imp.controller_id = w.id
	imp.original_side = -1
	imp.control_spell = "control_demon"
	imp.summon_spell = "summon_demon"
	w.spell_effects["shield"] = true
	w.poisoned = true
	c.state.board.darkness = true
	GlobalConsumables.nullify(c)
	check(w.spell_effects.is_empty())
	check(w.poisoned)
	check_eq(w.health, 13)
	check(imp.in_play())
	check_eq(imp.side, -1)
	check(not c.state.board.darkness)


func test_vacuum_and_wraith_immunity() -> void:
	var c := make_game(make_board(), [fig("thug", 0, Vector2(10, 10)), fig("wraith", -1, Vector2(11, 10)), fig("wraith", -1, Vector2(25, 25))], LoadedDice.new([1]))
	var a := c.state.figure(1)
	var t := c.state.figure(2)
	check_eq(Melee.resolve(LoadedDice.new([18, 1]), c.state.figures, a, t)["b_dmg"], 0)
	GlobalConsumables.vacuum(c, a)
	check(t.out_of_action)
	check(c.state.figure(3).in_play())
