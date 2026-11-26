extends TestCase


func _game(rolls: Array) -> GameController:
	var c := make_game(make_board(), [fig("wizard", 0, Vector2(10, 10)), fig("thug", 1, Vector2(14, 10))], LoadedDice.new(rolls))
	c.state.spell_catalog = JsonFile.read("res://data/spells.json")
	c.state.spellbooks[0] = {}
	c.state.active_id = 1
	c.state.active().actions_left = 2
	c.state.active().items.append({"scroll": "fleet_feet", "campaign_item": true})
	return c


func test_unknown_scroll_cast() -> void:
	var c := _game([1])
	check(c.start_cast("fleet_feet", 1))
	check_eq(c.cast_max_empowerment(), 0)
	check(c.finish_cast(0))
	check(c.state.active().spell_effects.has("fleet_feet"))
	check(c.state.active().items.is_empty())
	check_eq(c.state.active().health, 14)


func test_scroll_insurance() -> void:
	var c := _game([1])
	c.state.spellbooks[0] = {"fleet_feet": 10}
	check(c.start_cast("fleet_feet", 1))
	check(c._magic.can_insure())
	check(c._magic.insure())
	check(c.state.active().spell_effects.has("fleet_feet"))
	check_eq(c.state.active().health, 14)
	check(c.state.active().items.is_empty())
