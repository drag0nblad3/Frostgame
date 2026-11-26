extends TestCase


func test_hand_immobilizes_and_can_be_fought() -> void:
	var c := make_game(make_board(), [fig("wizard", 0, Vector2(10, 10)), fig("thug", 1, Vector2(14, 10))], LoadedDice.new([18, 18, 1]))
	c.state.spell_catalog = JsonFile.read("res://data/spells.json")
	c.state.spellbooks[0] = {"bones_of_the_earth": 10}
	c.state.active_id = 1
	c.state.active().actions_left = 2
	check(c.start_cast("bones_of_the_earth", 2))
	check(c.finish_cast(0))
	c.state.active_id = 2
	c.state.active().actions_left = 2
	check(not c.can_move())
	check(c.fight_hand(2))
	check(not c.state.figure(2).spell_effects.has("bones_of_the_earth"))


func test_circle_blocks_undead() -> void:
	var c := make_game(make_board(), [fig("wizard", 0, Vector2(10, 10)), fig("skeleton", -1, Vector2(15, 10))], LoadedDice.new([1]))
	c._magic.terrain.apply(c.state.figure(1), "circle_of_protection", Vector2(11, 10), false)
	check(TerrainMagic.ward_blocks(c.state.board, c.state.figure(2), Vector2(12, 10)))
	check(not TerrainMagic.ward_blocks(c.state.board, c.state.figure(1), Vector2(12, 10)))
	c.state.turn = 1
	c._magic.terrain.expire()
	check(not TerrainMagic.ward_blocks(c.state.board, c.state.figure(2), Vector2(12, 10)))
