extends TestCase


func test_reveal_ritual_and_saved_choice() -> void:
	var draft := WarbandDraft.new(db())
	draft.choose_defaults()
	var p := CampaignProgress.new()
	p.start(draft.as_warband())
	p.data["spells"] = {"reveal_secret": 12}
	check(Rituals.attempt(p.data, 0, "reveal_secret", "", LoadedDice.new([20])))
	check_eq(p.data["revealed_secrets"], 1)
	p.data["pending_treasure"] = [{"token": 1, "first": 1, "second": 3, "central": false}]
	p.data["gold"] = 0
	check(not p.can_deploy())
	check(p.resolve_treasure(true, LoadedDice.new([10])))
	check_eq(p.data["gold"], 200)
	check(p.can_deploy())


func test_central_reroll_accepts_second() -> void:
	var p := CampaignProgress.new()
	p.data = {"gold": 0, "loot": [], "last_report": [], "pending_treasure": [{"token": 0, "first": 3, "second": 0, "central": true}]}
	check(p.resolve_treasure(true, LoadedDice.new([1])))
	check_eq(p.data["gold"], 50)
	check(p.data["pending_treasure"].is_empty())
