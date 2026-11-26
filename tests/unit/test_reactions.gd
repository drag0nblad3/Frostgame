extends TestCase


func _game() -> GameController:
	var c := make_game(make_board(), [fig("thug", 0, Vector2(12, 11.5)), fig("thug", 1, Vector2(10, 10))], LoadedDice.new([8, 1]))
	c.state.forced_combat = true
	c.state.reaction_side = 0
	c.state.active_id = 2
	c.state.active().actions_left = 2
	return c


func test_guard_can_decline() -> void:
	var c := _game()
	check(c.move_to(MovePlanner.node_at(Vector2(14, 10))))
	check(c.awaiting_reaction())
	check_eq(c.state.active().pos, Vector2(10, 10))
	check(not c.can_move())
	check(c.answer_intercept(false))
	check(not c.awaiting_reaction())
	check_eq(c.state.active().pos, Vector2(14, 10))
	check_eq(c.state.active().actions_left, 1)


func test_guard_can_intercept() -> void:
	var c := _game()
	check(c.move_to(MovePlanner.node_at(Vector2(14, 10))))
	check(c.awaiting_reaction())
	check(c.answer_intercept(true))
	check(Contact.in_combat(c.state.figures, c.state.active()))
	check(not c.can_move())
