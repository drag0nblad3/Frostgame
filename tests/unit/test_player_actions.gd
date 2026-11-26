extends TestCase


func test_fight_preview_matches_action() -> void:
	var c := make_game(make_board(), [fig("knight", 0, Vector2(10, 10)), fig("thug", 1, Vector2(11, 10)), fig("thug", 1, Vector2(20, 20))], LoadedDice.new([15, 10]))
	check(not c.can_fight(2))
	c.state.active_id = 1
	c.state.active().actions_left = 2
	check(c.can_fight(2))
	check(not c.can_fight(3))
	check(c.fight(2))
	check(not c.can_fight(2))


func test_reload_preview_matches_action() -> void:
	var c := make_game(make_board(), [fig("crossbowman", 0, Vector2(10, 10)), fig("thug", 1, Vector2(20, 20))], Dice.new(1))
	c.state.active_id = 1
	var f := c.state.active()
	f.actions_left = 2
	check(not c.can_reload())
	f.loaded = false
	check(c.can_reload())
	check(c.reload())
	check(not c.can_reload())


func test_retreat_preview_does_not_spend_action() -> void:
	var c := make_game(make_board(), [fig("thug", 0, Vector2(2, 10)), fig("thug", 1, Vector2(20, 20))], Dice.new(1))
	c.state.active_id = 1
	c.state.active().actions_left = 2
	var r := c.reach()
	var edge := MovePlanner.node_at(Vector2(0.5, 10))
	check(c.can_exit_table(edge, r))
	check(not c.can_exit_table(MovePlanner.node_at(Vector2(3, 10)), r))
	check_eq(c.state.active().actions_left, 2)
	check(c.exit_table(edge))
	check(not c.can_exit_table(edge))
