extends TestCase


func test_potion_slots_and_purchase() -> void:
	var draft := WarbandDraft.new(db())
	draft.choose_defaults()
	var p := CampaignProgress.new()
	p.start(draft.as_warband())
	p.data["gold"] = 400
	check(CampaignInventory.buy(p.data, "healing"))
	check(CampaignInventory.buy(p.data, "strength"))
	check_eq(p.data["gold"], 225)
	check(CampaignInventory.assign_item(p.data, 0, 2, db()))
	check(not CampaignInventory.assign_item(p.data, 1, 2, db()))
	check(CampaignInventory.assign_item(p.data, 1, 0, db()))
	check_eq(CampaignInventory.loadout(p.data, 0).size(), 1)


func test_drink_and_buff() -> void:
	var c := make_game(make_board(), [fig("thug", 0, Vector2(10, 10)), fig("thug", 1, Vector2(20, 20))], Dice.new(1))
	c.state.active_id = 1
	var f := c.state.active()
	f.actions_left = 2
	f.items.append({"potion": "strength"})
	check(c._potions.drink("strength"))
	check_eq(f.effective_fight(), 3)
	check_eq(f.actions_left, 1)
	check(f.items.is_empty())
	check(c.can_act())


func test_potion_treasure_identification() -> void:
	var d := {"loot": []}
	CampaignInventory.identify(d, {"kind": "2 potions"}, LoadedDice.new([1, 20, 20]))
	check_eq(d["loot"].size(), 2)
	check_eq(d["loot"][0]["potion"], "healing")
	check_eq(d["loot"][1]["potion"], "life")
