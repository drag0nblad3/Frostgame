extends TestCase


func _campaign() -> CampaignProgress:
	var draft := WarbandDraft.new(db())
	draft.choose_defaults()
	var p := CampaignProgress.new()
	p.start(draft.as_warband())
	p.data["spells"] = {"brew_potion": 12, "familiar": 10, "animal_companion": 10, "absorb_knowledge": 12, "write_scroll": 12}
	p.data["games"] = 1
	return p


func test_ritual_attempts() -> void:
	var p := _campaign()
	check(Rituals.attempt(p.data, 0, "absorb_knowledge", "", LoadedDice.new([20])))
	check_eq(p.data["xp"], 40)
	check(not Rituals.attempt(p.data, 0, "absorb_knowledge", "", LoadedDice.new([20])))
	check(Rituals.attempt(p.data, 0, "write_scroll", "familiar", LoadedDice.new([20])))
	check_eq(p.data["loot"][0]["scroll"], "familiar")
	check(Rituals.attempt(p.data, 0, "brew_potion", "healing", LoadedDice.new([20])))
	check_eq(p.data["loot"][1]["potion"], "healing")
	check(Rituals.attempt(p.data, 0, "familiar", "", LoadedDice.new([20])))
	check_eq(p.deployment()["figures"][0]["stat_bonus"]["health"], 2)
	check(Rituals.attempt(p.data, 0, "animal_companion", "bear", LoadedDice.new([20])))
	check_eq(p.deployment()["figures"][4]["stat_bonus"]["will"], 3)
