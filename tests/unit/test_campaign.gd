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
