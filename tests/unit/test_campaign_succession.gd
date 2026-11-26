extends TestCase


func _campaign() -> CampaignProgress:
	var draft := WarbandDraft.new(db())
	draft.choose_defaults()
	var p := CampaignProgress.new()
	p.start(draft.as_warband())
	p.data["games"] = 1
	p.data["gold"] = 1000
	return p


func test_succession_requires_level_and_existing_apprentice() -> void:
	var p := _campaign()
	p.data["units"][0]["dead"] = true
	check_eq(CampaignSuccession.candidate(p.data), -1)
	check(not p.can_hire("apprentice", db()))
	p.data["level"] = 6
	check_eq(CampaignSuccession.candidate(p.data), 1)
	check(not CampaignSuccession.promote(p.data, " "))
	p.data["units"][1]["dead"] = true
	check_eq(CampaignSuccession.candidate(p.data), -1)


func test_succession_keeps_apprentice_stats_and_vault() -> void:
	var p := _campaign()
	p.data["level"] = 10
	p.data["advances"] = {"fight": 3, "health": 2}
	p.data["units"][1]["injury_types"] = {"crushed_arm": 1}
	p.data["units"][1]["injuries"] = 1
	var before: Dictionary = p.deployment()["figures"][1]
	p.data["loot"] = [{"kind": "potion", "potion": "healing", "owner": 0}, {"kind": "potion", "potion": "speed", "owner": 1}]
	p.data["units"][0]["dead"] = true
	check(CampaignSuccession.promote(p.data, "New Archmage"))
	check_eq(p.data["level"], 4)
	check_eq(p.data["name"], "New Archmage")
	check_eq(p.data["loot"].size(), 1)
	check_eq(p.data["loot"][0]["owner"], 1)
	check(p.data["units"][0]["dismissed"])
	var after: Dictionary = p.deployment()["figures"][0]
	check_eq(after["type"], "wizard")
	for key: String in ["fight", "will", "health"]:
		check_eq(int(db().get_def("wizard").get(key)) + int(after["stat_bonus"].get(key, 0)), int(db().get_def("apprentice").get(key)) + int(before["stat_bonus"].get(key, 0)))
	check(p.can_deploy())
	check(p.can_hire("apprentice", db()))


func test_grimoires_trade_only_if_known() -> void:
	var p := _campaign()
	p.data["spells"] = {"heal": 12}
	check(CampaignInventory.buy(p.data, "grimoire_fleet_feet"))
	check_eq(p.data["gold"], 500)
	check(not CampaignInventory.assign_item(p.data, 0, 0, db()))
	check(not CampaignInventory.sell(p.data, 0))
	check(CampaignInventory.buy(p.data, "grimoire_heal"))
	check(CampaignInventory.sell(p.data, 1))
	check_eq(p.data["gold"], 200)
	p.data["xp"] = 100
	check(p.learn_grimoire(0, db()))
	check(p.data["spells"].has("fleet_feet"))
	check_eq(p.data["loot"].size(), 0)
