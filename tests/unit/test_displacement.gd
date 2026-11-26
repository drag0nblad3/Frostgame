extends TestCase


func test_winner_can_withdraw() -> void:
	var c := make_game(make_board(), [fig("thug", 0, Vector2(10, 10)), fig("thug", 1, Vector2(11, 10))], LoadedDice.new([8, 1]))
	c.state.active_id = 1
	c.state.active().actions_left = 2
	check(c.fight(2))
	check(c.can_push(true))
	check(c.resolve_push(true))
	check_eq(c.state.figure(1).pos, Vector2(9, 10))
	check(c.can_move())


func test_tie_has_no_push() -> void:
	var c := make_game(make_board(), [fig("thug", 0, Vector2(10, 10)), fig("thug", 1, Vector2(11, 10))], LoadedDice.new([5, 5]))
	c.state.active_id = 1
	c.state.active().actions_left = 2
	check(c.fight(2))
	check(not c.can_push(false))


func test_dazzling_cape_leaves_combat_once() -> void:
	var c := make_game(make_board(),[fig("thug",0,Vector2(10,10)),fig("thug",1,Vector2(11,10))],Dice.new(5))
	var f := c.state.figure(1)
	c.state.active_id=f.id
	f.actions_left=2
	f.items.append({"gear":GearActions.CAPE,"gear_info":RedKingRewards.catalog()[GearActions.CAPE]})
	check(not c.can_move())
	check(GearActions.cape_ready(c))
	check(not c.move_to(Vector2i(20,20),true))
	check(ActiveGear.ready(f,GearActions.CAPE))
	check(c.move_to(Vector2i(16,20),true))
	check_eq(f.pos,Vector2(8,10))
	check_eq(f.moves_taken,1)
	check_eq(f.actions_left,1)
	check(not ActiveGear.ready(f,GearActions.CAPE))
