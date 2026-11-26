extends TestCase


func test_staff_and_gloves() -> void:
	var c := make_game(make_board(), [fig("wizard", 0, Vector2(10, 10)), fig("thug", 1, Vector2(25, 25))], LoadedDice.new([5]))
	c.state.spell_catalog = JsonFile.read("res://data/spells.json")
	c.state.spellbooks[0] = {"fleet_feet": 10}
	c.state.active_id = 1
	var f := c.state.active()
	f.actions_left = 2
	f.items.append({"gear": "gear_staff_casting", "casting_spell": "fleet_feet"})
	f.items.append({"gear": "gear_gloves_casting"})
	check(GearActions.arm(c, "gear_gloves_casting"))
	check(c.start_cast("fleet_feet", 1))
	check_eq(c.state.pending_cast["total"], 11)
	check(c.finish_cast(0))
	check(f.spell_effects.has("fleet_feet"))
	check(not ActiveGear.ready(f, "gear_gloves_casting"))


func test_teleport_ring_once() -> void:
	var c := make_game(make_board(), [fig("thug", 0, Vector2(10, 10)), fig("thug", 1, Vector2(25, 25))], Dice.new(1))
	c.state.active_id = 1
	var f := c.state.active()
	f.actions_left = 2
	f.items.append({"gear": "gear_ring_teleportation"})
	check(not GearActions.teleport(c, Vector2(19, 10)))
	check(GearActions.teleport(c, Vector2(18, 10)))
	check_eq(f.pos, Vector2(18, 10))
	check_eq(f.actions_left, 1)
	check(not ActiveGear.ready(f, "gear_ring_teleportation"))
