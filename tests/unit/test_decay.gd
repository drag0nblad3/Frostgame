extends TestCase


func test_decay_bow_and_dagger() -> void:
	var c := make_game(make_board(), [fig("wizard", 0, Vector2(10, 10)), fig("archer", 1, Vector2(14, 10))], LoadedDice.new([18]))
	c.state.spell_catalog = JsonFile.read("res://data/spells.json")
	c.state.spellbooks[0] = {"decay": 12}
	c.state.active_id = 1
	c.state.active().actions_left = 2
	var t := c.state.figure(2)
	check_eq(c._magic.counter_options("decay").size(), 2)
	check(c._magic.start_counter("decay", 0))
	check(c.finish_cast(0))
	check(t.ranged == null)
	check_eq(t.melee.id, "dagger")
	c._magic.weapons.destroy(t, "dagger")
	check_eq(t.melee.id, "unarmed")


func test_decay_ignores_magic_weapons() -> void:
	var c := make_game(make_board(), [fig("wizard", 0, Vector2(10, 10)), fig("thug", 1, Vector2(14, 10))], Dice.new(1))
	var t := c.state.figure(2)
	t.spell_effects["enchant_weapon"] = true
	check(c._magic.weapons.options(c.state.figure(1)).is_empty())
	t.spell_effects.clear()
	t.items.append({"gear": "gear_hand_weapon_damage", "gear_info": CampaignInventory.catalog()["gear_hand_weapon_damage"]})
	check(c._magic.weapons.options(c.state.figure(1)).is_empty())
