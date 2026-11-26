extends TestCase


func test_telescope_waits_for_choice_and_spends_once() -> void:
	var c := make_game(make_board(), [fig("wizard", 0, Vector2(4, 4)), fig("wizard", 1, Vector2(25, 25))], LoadedDice.new([3, 10, 9, 12]))
	c.state.reaction_side = 0
	c.state.telescope_ready[0] = true
	c.start_game()
	check(c.awaiting_reaction())
	check(c.activatable().is_empty())
	check(c.answer_initiative(false))
	check_eq(c.state.current_side(), 1)
	check(c.state.telescope_ready.has(0))
	c._flow.start_turn()
	check(c.awaiting_reaction())
	check(c.answer_initiative(true))
	check_eq(c.state.current_side(), 0)
	check(not c.state.telescope_ready.has(0))
	check(not c.answer_initiative(true))


func _campaign() -> CampaignProgress:
	var draft := WarbandDraft.new(db())
	draft.choose_defaults()
	var p := CampaignProgress.new()
	p.start(draft.as_warband())
	p.data["games"] = 1
	p.data["gold"] = 1000
	p.data["spells"] = {"summon_demon": 12, "control_demon": 12}
	check(p.choose_base("crypt"))
	check(BaseResources.buy(p.data, "summoning_circle"))
	check(BaseResources.buy(p.data, "summoning_candle"))
	check(BaseResources.buy(p.data, "arcane_candle"))
	return p


func test_circle_success_and_deployed_control() -> void:
	var p := _campaign()
	check(Rituals.choices(p.data, 1, "summon_demon").is_empty())
	check(Rituals.attempt(p.data, 0, "summon_demon", "", LoadedDice.new([17, 11])))
	check_eq(p.data["prepared_demon"]["type"], "minor_demon")
	check(not Rituals.attempt(p.data, 0, "summon_demon", "", LoadedDice.new([])))
	var scenario: Dictionary = JsonFile.read(ScenarioLoader.DIR + "treasure_skirmish.json")
	scenario["warbands"][0] = p.deployment()
	var state := ScenarioLoader.from_dict(scenario, db(), terrain())
	var c := GameController.new(state, LoadedDice.new([]))
	var wizard := state.figure(1)
	var demon: Figure = null
	for f in state.figures:
		if f.prepared_demon_caster == wizard.id:
			demon = f
	check(demon != null)
	if demon == null:
		return
	check_eq(demon.side, 0)
	check_eq(demon.original_side, -1)
	check_eq(demon.controller_id, wizard.id)
	check(not c._magic.available_spell(wizard, "summon_demon"))
	check(not c._magic.available_spell(wizard, "control_demon"))
	c._magic.summons.release(demon)
	check(not c._magic.available_spell(wizard, "summon_demon"))
	demon.out_of_action = true
	check(c._magic.available_spell(wizard, "summon_demon"))


func test_circle_failure_and_reset() -> void:
	var p := _campaign()
	check(Rituals.attempt(p.data, 0, "summon_demon", "", LoadedDice.new([18, 2])))
	check(p.data.get("prepared_demon", {}).is_empty())
	check(not Rituals.attempt(p.data, 0, "summon_demon", "", LoadedDice.new([])))
	check(p.choose_base("tower"))
	check(not BaseResources.owns(p.data, "summoning_circle"))
