extends TestCase


func _game(rolls: Array) -> GameController:
	var figs: Array[Figure] = [
		fig("wizard", 0, Vector2(5, 5)), fig("thug", 0, Vector2(8, 5)),
		fig("wizard", 1, Vector2(5, 30)), fig("thug", 1, Vector2(8, 30)),
	]
	return make_game(make_board(), figs, LoadedDice.new(rolls))


func test_initiative_order_and_reroll() -> void:
	var r := Initiative.roll(LoadedDice.new([7, 7, 3, 15]), 2)
	check_eq(r["order"], [1, 0], "tie rerolled, red wins")


func test_wizards_act_before_soldiers() -> void:
	var c := _game([12, 4])
	c.start_game()
	check_eq(c.state.phase, Phase.WIZARD, "wizard phase first")
	check_eq(c.state.current_side(), 0, "blue won initiative")
	check(not c.activate(2), "soldier can't act in wizard phase")
	check(c.activate(1), "blue wizard")
	c.end_activation()
	check_eq(c.state.current_side(), 1, "red wizard next")
	check(c.activate(3), "red wizard")
	c.end_activation()
	check_eq(c.state.phase, Phase.SOLDIER, "no apprentices, so soldiers")
	check_eq(c.state.current_side(), 0, "initiative winner first again")


func test_new_turn_after_everyone_acts() -> void:
	var c := _game([12, 4, 3, 9])
	c.start_game()
	for id in [1, 3, 2, 4]:
		check(c.activate(id), "activate %d" % id)
		c.end_activation()
	check_eq(c.state.turn, 2, "turn 2")
	check_eq(c.state.current_side(), 1, "red won turn 2")


func test_last_warband_standing_wins() -> void:
	var figs: Array[Figure] = [fig("knight", 0, Vector2(10, 10)), fig("thief", 1, Vector2(11, 10))]
	var c := make_game(make_board(), figs, LoadedDice.new([15, 1, 20, 1]))
	c.start_game()
	check(c.activate(1), "knight")
	c.fight(2)
	c.end_activation()
	check(c.state.over, "game over")
	check_eq(c.state.winner, 0, "blue wins")
