extends TestCase


func test_creatures_activate_by_health() -> void:
	var c := make_game(make_board(), [fig("thug", 0, Vector2(10, 10)), fig("thug", 1, Vector2(20, 20)), fig("giant_rat", -1, Vector2(15, 15)), fig("ghoul", -1, Vector2(16, 15))], LoadedDice.new([12, 4, 11, 5]))
	c.start_game()
	check(c.activate(1))
	c.end_activation()
	check(c.activate(2))
	c.end_activation()
	check_eq(c.state.phase, Phase.CREATURE)
	check_eq(c.activatable()[0].id, 4)
	check(c.activate(4))
	c.end_activation()
	check_eq(c.activatable()[0].id, 3)
	check(c.activate(3))
	c.end_activation()
	check_eq(c.state.turn, 2)


func test_uncontrolled_creatures_are_not_enemies() -> void:
	var a := fig("giant_rat", -1, Vector2(10, 10))
	var b := fig("ghoul", -1, Vector2(11, 10))
	var figs: Array[Figure] = [a, b]
	check(not Contact.in_combat(figs, a))
