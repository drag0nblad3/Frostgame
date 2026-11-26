extends TestCase


func test_fury_compels_charge() -> void:
	var c := make_game(make_board(), [fig("thug", 0, Vector2(10, 10)), fig("thug", 1, Vector2(14, 10)), fig("thug", 1, Vector2(18, 10))], LoadedDice.new([18, 1]))
	var f := c.state.figure(1)
	c.state.active_id = 1
	f.actions_left = 2
	f.spell_effects["potion_fury"] = true
	check_eq(f.effective_fight(), 3)
	check_eq(FuryRules.target(c.state, f).id, 2)
	check(not c.can_act())
	check(not c.can_end_activation())
	check(not c.move_to(MovePlanner.node_at(Vector2(8, 10))))
	check(c.move_to(MovePlanner.node_at(Vector2(13, 10))))
	check(c.can_fight(2))
	check(c.fight(2))
	check(c.can_end_activation())
