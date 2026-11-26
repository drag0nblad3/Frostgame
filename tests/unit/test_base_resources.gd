extends TestCase


func _campaign() -> CampaignProgress:
	var draft := WarbandDraft.new(db())
	draft.choose_defaults()
	var p := CampaignProgress.new()
	p.start(draft.as_warband())
	p.data["games"] = 1
	p.data["gold"] = 5000
	return p


func test_resources_purchase_and_switch() -> void:
	var p := _campaign()
	check(not BaseResources.buy(p.data, "carrier_pigeons"))
	check(p.choose_base("tower"))
	check(BaseResources.buy(p.data, "crystal_ball"))
	check(BaseResources.buy(p.data, "carrier_pigeons"))
	check(not BaseResources.buy(p.data, "crystal_ball"))
	check(not BaseResources.buy(p.data, "nonexistent_upgrade"))
	check_eq(p.data["gold"], 4700)
	check_eq(p.recruitment_cost("archer", db()), 65)
	check_eq(p.recruitment_cost("thug", db()), 0)
	p.data["spells"] = {"reveal_secret": 12}
	check(Rituals.attempt(p.data, 0, "reveal_secret", "", LoadedDice.new([9])))
	check_eq(p.data["revealed_secrets"], 1)
	check(p.choose_base("tower"))
	check(BaseResources.owns(p.data, "crystal_ball"))
	check(p.choose_base("crypt"))
	check(not BaseResources.owns(p.data, "carrier_pigeons"))
	check_eq(p.recruitment_cost("archer", db()), 75)


func test_inn_and_kennel_capacity() -> void:
	var p := _campaign()
	check(p.choose_base("inn"))
	for i in 7:
		check(p.hire("thug", db()))
	check(not p.can_hire("thug", db()))
	check(BaseResources.buy(p.data, "kennel"))
	check(p.hire("war_hound", db()))
	check(not p.can_hire("war_hound", db()))
	var choices := BaseResources.reserve_candidates(p.data, db())
	check_eq(choices.size(), 9)
	check(BaseResources.choose_reserve(p.data, choices[0], db()))
	var deploy: Array = p.deployment()["figures"]
	check_eq(deploy.size(), 11)
	for entry: Dictionary in deploy:
		check(int(entry.get("campaign_id", -1)) != choices[0])
	check(not p.choose_base("tower"))
	p.data["units"][choices[0]]["miss"] = 1
	check_eq(BaseResources.reserve_id(p.data, db()), -1)
	check_eq(p.deployment()["figures"].size(), 11)


func test_inn_fifth_specialist_requires_specialist_reserve() -> void:
	var p := _campaign()
	check(p.choose_base("inn"))
	for i in 5:
		check(p.hire("archer", db()))
	var choices := BaseResources.reserve_candidates(p.data, db())
	check_eq(choices.size(), 5)
	for id in choices:
		check_eq(p.data["units"][id]["type"], "archer")


func test_sarcophagus_and_ritual_bonuses() -> void:
	var p := _campaign()
	check(p.choose_base("library"))
	for id: String in ["giant_cauldron", "enchanters_workshop", "scriptorium", "sarcophagus_of_healing"]:
		check(BaseResources.buy(p.data, id))
	check_eq(BaseResources.casting_bonus(p.data, "brew_potion"), 1)
	check_eq(BaseResources.casting_bonus(p.data, "animate_construct"), 1)
	check_eq(BaseResources.casting_bonus(p.data, "embed_enchantment"), 1)
	check_eq(BaseResources.casting_bonus(p.data, "write_scroll"), 1)
	var unit: Dictionary = p.data["units"][0]
	unit["injury_types"] = {"niggling_injury": 1}
	check_eq(InjuryRules.treatment_price(p.data, unit), 20)
	unit["miss"] = 1
	var gold: int = p.data["gold"]
	check(p.treat(0))
	check_eq(p.data["gold"], gold)
	check_eq(unit["miss"], 0)
