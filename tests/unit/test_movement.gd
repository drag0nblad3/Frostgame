extends TestCase


func _reach(c: GameController, id: int) -> MoveReach:
	c.state.active_id = id
	c.state.active().actions_left = 2
	return c.reach()


func test_open_ground_full_move() -> void:
	var c := make_game(make_board(), [fig("thug", 0, Vector2(10, 10))], Dice.new(1))
	var r := _reach(c, 1)
	check(r.can_reach(MovePlanner.node_at(Vector2(16, 10))), "6\" straight is reachable")
	check(not r.can_reach(MovePlanner.node_at(Vector2(17, 10))), "7\" is too far")


func test_rough_terrain_costs_double() -> void:
	var board := make_board([["rubble", 11, 0, 10, 36]])
	var c := make_game(board, [fig("thug", 0, Vector2(10, 10))], Dice.new(1))
	var r := _reach(c, 1)
	check(r.can_reach(MovePlanner.node_at(Vector2(13, 10))), "1\" clear + 2\" rough = 5\"")
	check(not r.can_reach(MovePlanner.node_at(Vector2(14.5, 10))), "1\" clear + 3.5\" rough = 8\"")


func test_ruins_block_movement() -> void:
	var board := make_board([["ruin", 12, 0, 2, 36]])
	var c := make_game(board, [fig("thug", 0, Vector2(10, 10))], Dice.new(1))
	var r := _reach(c, 1)
	check(not r.can_reach(MovePlanner.node_at(Vector2(15, 10))), "can't pass a wall across the table")


func test_move_stops_on_contact() -> void:
	var c := make_game(make_board(), [fig("thug", 0, Vector2(10, 10)), fig("thug", 1, Vector2(13, 10))], Dice.new(1))
	var r := _reach(c, 1)
	check(r.can_reach(MovePlanner.node_at(Vector2(12, 10))), "can reach contact")
	check(not r.can_reach(MovePlanner.node_at(Vector2(13, 10))), "can't stand on the enemy")
	check(not r.can_reach(MovePlanner.node_at(Vector2(15, 10))), "can't pass through contact")


func test_second_move_is_half() -> void:
	var c := make_game(make_board(), [fig("thug", 0, Vector2(10, 10))], Dice.new(1))
	c.state.active_id = 1
	var f := c.state.active()
	f.actions_left = 2
	check(c.move_to(MovePlanner.node_at(Vector2(16, 10))), "first move")
	check_eq(MoveRules.allowance(f), 3.0, "second move allowance")
	check(not c.reach().can_reach(MovePlanner.node_at(Vector2(20, 10))), "4\" second move too far")
	check(c.move_to(MovePlanner.node_at(Vector2(19, 10))), "3\" second move")
	check(not c.can_move(), "out of actions")


func test_cannot_move_in_combat() -> void:
	var c := make_game(make_board(), [fig("thug", 0, Vector2(10, 10)), fig("thug", 1, Vector2(11, 10))], Dice.new(1))
	c.state.active_id = 1
	c.state.active().actions_left = 2
	check(not c.can_move(), "engaged figures stay put")


func test_run_for_it_and_talisman() -> void:
	var f := fig("wizard",0,Vector2(10,10))
	var t := fig("thug",1,Vector2(10,14))
	var c := make_game(make_board(),[f,t],Dice.new(2))
	c.state.active_id=f.id
	f.actions_left=f.action_limit()
	f.items.append({"gear":RunForIt.TALISMAN,"gear_info":RedKingRewards.catalog()[RunForIt.TALISMAN]})
	check(RunForIt.ready(c))
	check(not RunForIt.reach(c).can_reach(Vector2i(30,20)))
	check(RunForIt.reach(c,true).can_reach(Vector2i(30,20)))
	check(not RunForIt.reach(c,true).can_reach(Vector2i(20,27)))
	check(RunForIt.apply(c,Vector2i(30,20),true))
	check_eq(f.pos,Vector2(15,10))
	check_eq(f.actions_left,0)
	check(not ActiveGear.ready(f,RunForIt.TALISMAN))
