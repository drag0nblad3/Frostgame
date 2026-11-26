extends TestCase


func test_hammer_graft() -> void:
	var d := {"units": [{"id": 0, "type": "medium_construct", "dead": false}], "loot": [{"kind": "gear", "gear": "gear_construct_hammer", "owner": -1}, {"kind": "gear", "gear": "gear_construct_hammer", "owner": -1}]}
	check(CampaignInventory.assign_item(d, 0, 0, db()))
	check(not CampaignInventory.assign_item(d, 1, 0, db()))
	check(not CampaignInventory.assign_item(d, 0, -1, db()))
	var f := fig("medium_construct", 0, Vector2(10, 10))
	f.items.assign(CampaignInventory.loadout(d, 0))
	check_eq(MagicEquipment.bonus(f, "melee_damage"), 1)
	check(WeaponActions.magic_attack(f, f.melee))


func test_fate_replaces_cast_roll() -> void:
	var c := make_game(make_board(), [fig("wizard", 0, Vector2(10, 10)), fig("thug", 1, Vector2(25, 25))], LoadedDice.new([2, 18]))
	c.state.spell_catalog = JsonFile.read("res://data/spells.json")
	c.state.spellbooks[0] = {"fleet_feet": 10}
	c.state.active_id = 1
	var f := c.state.active()
	f.actions_left = 2
	f.items.append({"gear": "gear_fate_stone"})
	check(c.start_cast("fleet_feet", 1))
	check(c._magic.reroll_fate())
	check_eq(c.state.pending_cast["raw"], 18)
	check(not c._magic.reroll_fate())
	check(c.finish_cast(0))
