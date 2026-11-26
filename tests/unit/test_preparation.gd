extends TestCase


func test_awareness_and_illusion_preparation() -> void:
	var draft := WarbandDraft.new(db())
	draft.choose_defaults()
	var p := CampaignProgress.new()
	p.start(draft.as_warband())
	p.data["spells"] = {"awareness": 12, "illusionary_soldier": 12}
	check(Rituals.attempt(p.data, 0, "awareness", "", LoadedDice.new([20])))
	check(Rituals.attempt(p.data, 0, "illusionary_soldier", "archer", LoadedDice.new([20])))
	var deployed: Array = p.deployment()["figures"]
	check(deployed[0]["awareness"])
	check_eq(deployed[-1]["type"], "archer")
	check(deployed[-1]["prepared_illusion"])
	check(Rituals.choices(p.data, 1, "illusionary_soldier").is_empty())
	check_eq(Initiative.roll(LoadedDice.new([10, 11]), 2, {0: 2})["order"][0], 0)


func test_familiar_lost() -> void:
	var c := make_game(make_board(), [fig("wizard", 0, Vector2(10, 10)), fig("thug", 1, Vector2(20, 20))], Dice.new(1))
	var f := c.state.figure(1)
	f.def = f.def.with_bonuses({"health": 2})
	f.familiar = true
	f.health = 2
	c._hurt(f, 1, c.state.figure(2), false)
	check(not f.familiar)
	check_eq(f.def.health, 14)
	check_eq(f.health, 1)
