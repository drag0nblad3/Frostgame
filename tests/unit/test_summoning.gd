extends TestCase


func _game(rolls: Array) -> GameController:
	var c := make_game(make_board(), [fig("wizard", 0, Vector2(10, 10)), fig("skeleton", -1, Vector2(14, 10)), fig("thug", 1, Vector2(20, 20))], LoadedDice.new(rolls))
	c.state.creature_db = db()
	c.state.spell_catalog = JsonFile.read("res://data/spells.json")
	c.state.spellbooks[0] = {"raise_zombie": 10, "control_undead": 12, "summon_demon": 12}
	c.state.active_id = 1
	c.state.active().actions_left = 2
	return c


func test_control_and_release() -> void:
	var c := _game([18, 1])
	check(c.start_cast("control_undead", 2))
	check(c.finish_cast(0))
	check_eq(c.state.figure(2).side, 0)
	check_eq(c.state.figure(2).original_side, -1)
	c.state.active().acted = false
	check(c._magic.cancel(2))
	check_eq(c.state.figure(2).side, -1)


func test_zombie_limit() -> void:
	var c := _game([18])
	check(c._magic.start_at("raise_zombie", Vector2(10, 11)))
	check(c.finish_cast(0))
	check_eq(c.state.figures.size(), 4)
	check_eq(c.state.figure(4).def.id, "zombie")
	check_eq(c.state.figure(4).side, 0)
	c.state.active().acted = false
	check(c._magic.placement_points("raise_zombie", true).is_empty())


func test_demon_empowerment() -> void:
	var c := _game([20])
	check(c._magic.start_at("summon_demon", Vector2(10, 11)))
	check(c.cast_max_empowerment() > 5)
	check(c.finish_cast(5))
	check_eq(c.state.figure(4).def.id, "major_demon")
	check_eq(c.state.figure(4).controller_id, 1)
