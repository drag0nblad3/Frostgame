extends TestCase


func test_poison_and_heal() -> void:
	var c := make_game(make_board(), [fig("thug", 0, Vector2(10, 10)), fig("ice_spider", -1, Vector2(11, 10)), fig("skeleton", -1, Vector2(20, 20))], Dice.new(1))
	var a := c.state.figure(1)
	c._hurt(a, 1, c.state.figure(2))
	check(a.poisoned)
	check_eq(a.action_limit(), 1)
	c._magic._heal(a, 1)
	check(not a.poisoned)
	check_eq(a.action_limit(), 2)
	check(c.state.figure(3).immune_to_poison())


func test_spell_modifiers_and_expiry() -> void:
	var c := make_game(make_board(), [fig("thug", 0, Vector2(10, 10)), fig("thug", 1, Vector2(20, 20))], LoadedDice.new([20, 20, 20]))
	var a := c.state.figure(1)
	a.spell_effects = {"curse": 14, "slow": 14, "furious_quill": 14}
	check_eq(a.action_limit(), 1)
	check_eq(a.roll_penalty(), -2)
	check_eq(a.effective_fight(), 0)
	check_eq(a.effective_move(), 5)
	check_eq(a.effective_shoot(), -4)
	c._magic.on_activate(a)
	check(not a.spell_effects.has("furious_quill"))
	c._magic.on_end_activation(a)
	check_eq(a.action_limit(), 2)
	c._magic.on_end_turn()
	check_eq(a.roll_penalty(), 0)
