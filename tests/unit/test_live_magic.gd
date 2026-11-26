extends TestCase


func _game(rolls: Array, role: String = "wizard") -> GameController:
	var c := make_game(make_board(), [fig(role, 0, Vector2(10, 10)), fig("thug", 0, Vector2(12, 10)), fig("thug", 1, Vector2(20, 10))], LoadedDice.new(rolls))
	c.state.spell_catalog = JsonFile.read("res://data/spells.json")
	c.state.spellbooks[0] = {"heal": 8, "strength": 10, "elemental_bolt": 12, "elemental_shield": 10}
	c.state.active_id = 1
	c.state.active().actions_left = 2
	return c


func test_empower_heal() -> void:
	var c := _game([6])
	c.state.figure(2).health = 4
	check(c.start_cast("heal", 2))
	check(not c.can_move())
	check(c.finish_cast(2))
	check_eq(c.state.figure(1).health, 12)
	check_eq(c.state.figure(2).health, 9)
	check(not c.can_cast("strength", 2))


func test_failure_damage() -> void:
	var c := _game([3], "apprentice")
	check(c.start_cast("strength", 2))
	check(c.finish_cast(0))
	check_eq(c.state.figure(1).health, 11)
	check(not c.state.figure(2).spell_effects.has("strength"))


func test_buff_and_shield() -> void:
	var c := _game([14, 14])
	check(c.start_cast("strength", 2))
	check(c.finish_cast(0))
	check_eq(c.state.figure(2).effective_fight(), 4)
	c.state.active().acted = false
	check(c.start_cast("elemental_shield", 1))
	check(c.finish_cast(0))
	c._hurt(c.state.figure(1), 5, c.state.figure(3))
	check_eq(c.state.figure(1).health, 12)
	check_eq(c.state.figure(1).elemental_shield, 0)
