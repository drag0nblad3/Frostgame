extends TestCase


func test_beauty_blocks_repeat_shots() -> void:
	var c := make_game(make_board(), [fig("wizard", 0, Vector2(10, 10)), fig("archer", 1, Vector2(14, 10))], LoadedDice.new([18, 1]))
	c.state.spell_catalog = JsonFile.read("res://data/spells.json")
	c.state.spellbooks[0] = {"beauty": 10}
	c.state.active_id = 1
	c.state.active().actions_left = 2
	check(c.start_cast("beauty", 1))
	check(c.finish_cast(0))
	c.state.active_id = 2
	c.state.active().actions_left = 2
	check(c.shoot(1))
	check_eq(c.state.figure(1).health, 14)
	check(not c.can_shoot(1))
	check_eq(c.state.active().actions_left, 2)
	c.state.turn += 1
	check(c.can_shoot(1))
