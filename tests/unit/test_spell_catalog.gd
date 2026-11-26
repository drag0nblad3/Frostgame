extends TestCase


func test_catalog_complete() -> void:
	var d := WarbandDraft.new(db())
	check_eq(d.catalog.size(), 80)
	for school: String in d.schools:
		d.school = school
		check_eq(d.candidates(0).size(), 8)
		d.choose_defaults()
		check(d.errors().is_empty())


func test_storm_and_petrification() -> void:
	var c := make_game(make_board(), [fig("wizard", 0, Vector2(10, 10)), fig("thug", 1, Vector2(12, 10))], LoadedDice.new([18, 18, 1]))
	c.state.spell_catalog = JsonFile.read("res://data/spells.json")
	c.state.spellbooks[0] = {"call_storm": 12, "petrify": 10}
	c.state.active_id = 1
	var caster := c.state.active()
	caster.actions_left = 2
	check(c.start_cast("call_storm", 1))
	check(c.finish_cast(0))
	check_eq(c.state.storm_penalty, 1)
	caster.acted = false
	check(c.start_cast("petrify", 2))
	check(c.finish_cast(0))
	var target := c.state.figure(2)
	check_eq(target.action_limit(), 0)
	check_eq(target.effective_fight(), 0)
	c._magic.on_end_activation(target)
	check_eq(target.action_limit(), 2)
	check_eq(target.effective_fight(), 0)
