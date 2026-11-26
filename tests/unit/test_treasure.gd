extends TestCase


func _game(type: String = "thug", at: Vector2 = Vector2(3, 10)) -> GameController:
	var c := make_game(make_board(), [fig(type, 0, at), fig("thug", 1, Vector2(25, 25))], Dice.new(1))
	c.state.treasures.append(TreasureToken.new(0, at + Vector2(0.5, 0)))
	c.state.active_id = 1
	c.state.active().actions_left = 2
	return c


func test_pickup_and_encumbrance() -> void:
	var c := _game("knight")
	check(c.pick_up(0))
	check_eq(c.state.active().treasure_id, 0)
	check_eq(c.state.active().effective_fight(), 3)
	check_eq(MoveRules.allowance(c.state.active()), 2.5)
	check_eq(c.state.active().actions_left, 1)


func test_animal_cannot_collect() -> void:
	check(not _game("war_hound").pick_up(0))


func test_enemy_blocks_collection() -> void:
	var c := _game()
	c.state.figure(2).pos = Vector2(4.5, 10)
	check(not c.pick_up(0))


func test_extraction_is_not_a_casualty() -> void:
	var c := _game("thug", Vector2(2, 10))
	check(c.pick_up(0))
	check(c.exit_table(MovePlanner.node_at(Vector2(0.5, 10))))
	check_eq(c.state.secured_count(0), 1)
	check(c.state.figure(1).exited)
	check(not c.state.figure(1).out_of_action)
	check(not c.state.figure(1).in_play())
	check_eq(TreasureRules.winner(c.state), 0)


func test_death_drops_treasure() -> void:
	var c := _game()
	check(c.pick_up(0))
	var carrier := c.state.active()
	c._hurt(carrier, 100, c.state.figure(2))
	check(c.state.treasure(0).on_ground())
	check_eq(c.state.treasure(0).pos, carrier.pos)
	check_eq(carrier.treasure_id, -1)


func test_drop_costs_action() -> void:
	var c := _game()
	check(c.pick_up(0))
	check(c.drop_treasure(Vector2(3, 11)))
	check(c.state.treasure(0).on_ground())
	check_eq(c.state.active().actions_left, 0)


func test_scenario_has_five_tokens() -> void:
	var s := ScenarioLoader.load_id("treasure_skirmish", db(), terrain())
	check_eq(s.treasures.size(), 5)
	for token in s.treasures:
		check(s.board.can_stand(token.pos, TreasureRules.TOKEN_RADIUS))
