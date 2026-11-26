extends TestCase


func test_embed_ritual_creates_permanent_weapon() -> void:
	var draft := WarbandDraft.new(db())
	draft.choose_defaults()
	var p := CampaignProgress.new()
	p.start(draft.as_warband())
	p.data["games"] = 1
	p.data["spells"] = {"embed_enchantment": 14}
	p.data["enchantments"] = [{"gear": "gear_hand_weapon_fight", "unit": 2}]
	check(Rituals.attempt(p.data, 0, "embed_enchantment", "0", LoadedDice.new([20])))
	check_eq(p.data["loot"][0]["gear"], "gear_hand_weapon_fight")
	check(p.data["enchantments"].is_empty())
	check(CampaignInventory.assign_item(p.data, 0, 2, db()))
	check_eq(CampaignInventory.loadout(p.data, 2)[0]["gear_info"]["bonus"]["fight"], 1)
