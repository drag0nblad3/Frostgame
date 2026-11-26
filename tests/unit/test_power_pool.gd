extends TestCase


func test_power_cast() -> void:
	var c := make_game(make_board(), [fig("wizard", 0, Vector2(10, 10)), fig("thug", 1, Vector2(14, 10))], LoadedDice.new([7]))
	c.state.spell_catalog = JsonFile.read("res://data/spells.json")
	c.state.spellbooks[0] = {"fleet_feet": 10}
	c.state.active_id = 1
	var f := c.state.active()
	f.actions_left = 2
	f.items.append({"gear": "gear_staff_power2"})
	f.items.append({"gear": "gear_orb_power6"})
	check(c.start_cast("fleet_feet", 1))
	check(c.finish_cast(3))
	check_eq(f.health, 14)
	check_eq(PowerPool.available(f), 5)
	check_eq(PowerPool.remaining(f.items[0]), 0)
	check_eq(PowerPool.remaining(f.items[1]), 5)


func test_orb_persists() -> void:
	var c := make_game(make_board(), [fig("wizard", 0, Vector2(10, 10)), fig("thug", 1, Vector2(14, 10))], Dice.new(1))
	var f := c.state.figure(1)
	f.campaign_id = 0
	var d := {"loot": [{"kind": "gear", "gear": "gear_orb_power6", "owner": 0}]}
	f.items.assign(CampaignInventory.loadout(d, 0))
	check_eq(PowerPool.spend(f, 4), 4)
	CampaignInventory.settle(d, c, 0)
	check_eq(d["loot"][0]["power_left"], 2)
	f.items.assign(CampaignInventory.loadout(d, 0))
	check_eq(PowerPool.spend(f, 2), 2)
	CampaignInventory.settle(d, c, 0)
	check(d["loot"].is_empty())
