extends TestCase


func test_treasure_table() -> void:
	check_eq(CampaignProgress.treasure(LoadedDice.new([2, 7]))["gold"], 70)
	check_eq(CampaignProgress.treasure(LoadedDice.new([20]))["kind"], "grimoire")


func test_campaign_survival_and_progression() -> void:
	var d := WarbandDraft.new(db())
	d.choose_defaults()
	var p := CampaignProgress.new()
	p.start(d.as_warband())
	var c := make_game(make_board(), [fig("wizard", 0, Vector2(10, 10)), fig("thug", 0, Vector2(12, 10)), fig("thug", 1, Vector2(20, 20))], Dice.new(1))
	c.state.figure(1).campaign_id = 0
	c.state.figure(2).campaign_id = 2
	c.state.figure(2).out_of_action = true
	c.state.over = true
	var token := TreasureToken.new(0, Vector2.ZERO)
	token.secured_by = 0
	c.state.treasures.append(token)
	check(p.settle(c, LoadedDice.new([5, 1])))
	check_eq(p.data["xp"], 80)
	check(not p.can_deploy())
	check(p.resolve_treasure(false, LoadedDice.new([])))
	check_eq(p.data["gold"], d.BUDGET - d.cost() + 50)
	check_eq(p.data["units"][2]["miss"], 1)
	check_eq(p.deployment()["figures"].size(), 3)
	p.data["xp"] = 200
	var id: String = d.spells[0]
	check(p.improve_spell(id))
	check(not p.improve_spell(id))
	check_eq(p.data["level"], 1)
	check(p.save("user://campaign_test.json"))
	var loaded := CampaignProgress.new()
	check(loaded.load_save("user://campaign_test.json"))
	check_eq(loaded.data["level"], 1.0)
	DirAccess.remove_absolute("user://campaign_test.json")


func test_campaign_recruit_and_advancement() -> void:
	var d := WarbandDraft.new(db())
	d.choose_defaults()
	var p := CampaignProgress.new()
	p.start(d.as_warband())
	p.data["gold"] = 500
	p.data["xp"] = 300
	check(p.hire("archer", db()))
	check_eq(p.data["gold"], 425)
	check(not p.hire("apprentice", db()))
	check(p.improve_stat("fight", db()))
	check(not p.improve_stat("will", db()))
	check_eq(p.deployment()["figures"][0]["stat_bonus"]["fight"], 1)
	check_eq(p.deployment()["figures"][1]["stat_bonus"]["fight"], 1)
	check(p.dismiss(4))
	check_eq(p.deployment()["figures"].size(), 4)
	check(not p.choose_base("brewery"))
	p.data["games"] = 1
	check(p.choose_base("brewery"))
	check_eq(p.deployment()["figures"][2]["stat_bonus"]["will"], 1)
	check_eq(CampaignProgress.random_spell(LoadedDice.new([20, 20])), "destroy_undead")


func test_deployment_blockers_and_prepared_caster() -> void:
	var draft := WarbandDraft.new(db())
	draft.choose_defaults()
	var p := CampaignProgress.new()
	p.start(draft.as_warband())
	p.data["units"][0]["miss"]=1
	p.data["prepared_zombie"]=true
	p.data["prepared_zombie_caster"]=0
	check(p.can_deploy(),"core permits a resting wizard to miss a normal game")
	for entry: Dictionary in p.deployment()["figures"]:
		check(not entry.get("prepared_zombie",false))
	p.data["pending_treasure"]=[{"token":0}]
	check(not p.can_deploy())
	check(not p.deployment_blockers().is_empty())
