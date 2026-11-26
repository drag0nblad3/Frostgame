extends TestCase


func test_caster_weapon_slots_and_magic_dagger() -> void:
	var draft := WarbandDraft.new(db())
	draft.choose_defaults()
	draft.wizard_weapons = ["two_handed", "bow", "dagger"]
	var p := CampaignProgress.new()
	p.start(draft.as_warband())
	p.data["gold"] = 2000
	check_eq(CasterLoadout.weapon_slots(draft.wizard_weapons), 4)
	check(CampaignInventory.buy(p.data, "gear_dagger_fight"))
	check(CampaignInventory.assign_item(p.data, 0, 0, db()))
	check(CampaignInventory.buy(p.data, "healing"))
	check(CampaignInventory.assign_item(p.data, 1, 0, db()))
	check(CampaignInventory.buy(p.data, "speed"))
	check(not CampaignInventory.assign_item(p.data, 2, 0, db()))
	check(not CasterLoadout.set_weapons(p.data, 0, ["bow", "crossbow"]))
	var entry: Dictionary = p.deployment()["figures"][0]
	check_eq(entry["weapons"], ["two_handed", "bow", "dagger"])
	var scenario: Dictionary = JsonFile.read(ScenarioLoader.DIR + "treasure_skirmish.json")
	scenario["warbands"][0] = p.deployment()
	var s := ScenarioLoader.from_dict(scenario, db(), terrain())
	var c := GameController.new(s, Dice.new(2))
	var wizard := s.figure(1)
	check_eq(wizard.ranged.id, "bow")
	check_eq(wizard.melee.id, "two_handed")
	s.active_id = 1
	wizard.actions_left = 2
	check(c.select_melee("dagger"))
	check_eq(wizard.melee.id, "dagger")
	check_eq(MagicEquipment.bonus(wizard, "fight", "dagger"), 1)
	wizard.acted = true
	check(not c.select_melee("two_handed"))


func test_caster_magic_weapon_adds_new_type() -> void:
	var draft := WarbandDraft.new(db())
	draft.choose_defaults()
	var p := CampaignProgress.new()
	p.start(draft.as_warband())
	p.data["gold"] = 1000
	check(CampaignInventory.buy(p.data, "gear_hand_weapon_damage"))
	check(CampaignInventory.assign_item(p.data, 0, 0, db()))
	check(p.deployment()["figures"][0]["weapons"].has("hand_weapon"))
	check_eq(CasterLoadout.carried(p.data, p.data["units"][0])["slots"], 2)
