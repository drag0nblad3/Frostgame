extends TestCase


func _game() -> GameController:
	var figs: Array[Figure] = [
		fig("wizard", 0, Vector2(5, 5)), fig("thug", 0, Vector2(8, 5)),
		fig("crossbowman", 0, Vector2(5, 8)), fig("thug", 0, Vector2(5, 2)),
		fig("wizard", 1, Vector2(30, 30)), fig("thug", 1, Vector2(11, 5)),
	]
	var c := make_game(make_board(), figs, LoadedDice.new([12, 4, 15, 10]))
	c.start_game()
	return c


func test_group_requires_caster_and_unique_eligible_members() -> void:
	var c := _game()
	check(c.can_begin_group())
	check(not c.begin_group([2, 3]), "caster required")
	check(not c.begin_group([1, 2, 2]), "duplicates forbidden")
	check(not c.begin_group([1, 5]), "enemy forbidden")
	check(c.begin_group([1, 2, 3]))
	check(not c.can_begin_group())
	check(not c.activate(4), "unselected soldier forbidden")


func test_move_pass_precedes_second_actions() -> void:
	var c := _game()
	check(c.begin_group([1, 2]))
	check(c.activate(2))
	check(not c.can_act())
	check(c.move_to(MovePlanner.node_at(Vector2(10, 5))))
	check(not c.fight(6))
	c.end_activation()
	check(not c.activate(2), "cannot move twice during movement pass")
	check(c.activate(1))
	c.end_activation()
	check_eq(c.state.group.stage, GroupActivation.SECOND)
	check(c.activate(2))
	check(c.can_fight(6))
	check(c.fight(6))
	c.end_activation()
	check(c.activate(1))
	c.end_activation()
	check(not c.state.group.in_progress())
	check(c.state.figure(2).activated)
	check(not c.state.figure(3).activated, "unselected soldier deferred")
	check_eq(c.state.current_side(), 1)


func test_second_move_half_and_no_movement_substitute() -> void:
	var c := _game()
	c.state.figure(3).loaded = false
	check(c.begin_group([1, 3]))
	check(c.activate(3))
	check(not c.can_reload())
	c.end_activation()
	check(c.activate(1))
	check(c.move_to(MovePlanner.node_at(Vector2(3, 5))))
	c.end_activation()
	check(c.activate(1))
	check_eq(MoveRules.allowance(c.state.active()), 3.0)
	c.end_activation()
	check(c.activate(3))
	check(c.can_reload())
	check(c.reload())
	c.end_activation()
	check(c.state.figure(3).loaded)


func test_cannot_declare_after_individual_activation() -> void:
	var c := _game()
	check(c.activate(1))
	c.end_activation()
	check(not c.can_begin_group())
