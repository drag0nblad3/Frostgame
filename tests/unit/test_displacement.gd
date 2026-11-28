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


func test_slippery_boots_tie_and_long_retreat() -> void:
	var c := make_game(make_board(),[fig("thug",0,Vector2(10,10)),fig("thug",1,Vector2(11,10))],LoadedDice.new([5,5]))
	var f := c.state.figure(1)
	f.items.append({"gear":CombatDisplacement.BOOTS,"gear_info":RedKingRewards.catalog()[CombatDisplacement.BOOTS]})
	c.state.active_id=f.id
	f.actions_left=2
	check(c.fight(2))
	check(c.state.push_tie)
	check(not c.can_push(false))
	check(c.can_push(true,3.0))
	check(not c.can_push(true,3.5))
	check(c.resolve_push(true,2.5))
	check_eq(f.pos,Vector2(7.5,10))
	check(not c.state.push_tie)


func test_ordinary_bootless_withdrawal_unchanged() -> void:
	var c := make_game(make_board(),[fig("thug",0,Vector2(10,10)),fig("thug",1,Vector2(11,10))],LoadedDice.new([8,1]))
	c.state.active_id=1
	c.state.active().actions_left=2
	check(c.fight(2))
	check(c.can_push(true))
	check(not c.can_push(true,2.0))


func test_immobilized_guards_cannot_intercept() -> void:
	var f:=fig("wizard",0,Vector2(9,12))
	var g:=fig("thug",1,Vector2(12,12))
	var c:=make_game(make_board(),[f,g],Dice.new(17))
	check(c._displacement.guard_can_intercept(f,g,[]))
	g.spell_effects["bones_of_the_earth"]=true
	check(not c._displacement.guard_can_intercept(f,g,[]))
	g.spell_effects.erase("bones_of_the_earth")
	g.spell_effects["petrify"]=true
	check(not c._displacement.guard_can_intercept(f,g,[]))
