extends TestCase


func test_telekinesis_central_and_range() -> void:
	var c := make_game(make_board(), [fig("wizard", 0, Vector2(10, 10)), fig("thug", 1, Vector2(25, 25))], LoadedDice.new([18]))
	c.state.spell_catalog = JsonFile.read("res://data/spells.json")
	c.state.spellbooks[0] = {"telekinesis": 10}
	c.state.active_id = 1
	c.state.active().actions_left = 2
	c.state.treasures.append(TreasureToken.new(0, Vector2(14, 10)))
	c.state.treasures.append(TreasureToken.new(1, Vector2(15, 10)))
	check(not c._magic.start_treasure("telekinesis", 0, Vector2(16, 10)))
	check(c._magic.start_treasure("telekinesis", 1, Vector2(18, 10)))
	check(c.finish_cast(0))
	check_eq(c.state.treasure(1).pos, Vector2(18, 10))
