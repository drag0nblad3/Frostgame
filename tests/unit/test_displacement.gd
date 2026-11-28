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


func test_dazzling_cape_can_escape_by_leaping_gap() -> void:
	var b:=make_board()
	b.floor_layout={"surfaces":[{"id":"west","rect":[0,0,4,6],"level":3},{"id":"east","rect":[4,0,5,6],"level":3}],"jumps":[{"from":["west",3.5,3],"to":["east",4.5,3]}]}
	var f:=fig("thug",0,Vector2(3.5,3))
	f.surface_id="west"
	f.elevation=3.0
	var enemy:=fig("thug",1,Vector2(2.5,3))
	enemy.surface_id="west"
	enemy.elevation=3.0
	var c:=make_game(b,[f,enemy],Dice.new(19))
	c.state.active_id=f.id
	f.actions_left=2
	f.items.append({"gear":GearActions.CAPE,"gear_info":RedKingRewards.catalog()[GearActions.CAPE]})
	var n:=b.floor_geometry().node("east",Vector2(5.5,3))
	check(not c.can_move())
	check(GearActions.cape_ready(c))
	check(not c.movement_options("jump").cost.has(n))
	var options:=c.movement_options("gear_cape_move")
	check(options.jumps.has(n))
	check(ActiveGear.ready(f,GearActions.CAPE))
	check(not c.commit_movement("gear_cape_move",Vector3i(999,999,0)))
	check(ActiveGear.ready(f,GearActions.CAPE))
	check(c.commit_movement("gear_cape_move",n))
	check_eq(f.surface_id,"east")
	check_eq(f.pos,Vector2(5.5,3))
	check_eq(f.moves_taken,1)
	check_eq(f.actions_left,1)
	check(not ActiveGear.ready(f,GearActions.CAPE))


func test_dazzling_cape_can_escape_by_dropping_from_ledge() -> void:
	var b:=make_board()
	b.floor_layout={"surfaces":[{"id":"street","rect":[0,0,36,36],"level":0},{"id":"deck","rect":[8,8,5,5],"level":2}]}
	var f:=fig("thug",0,Vector2(12.5,10))
	f.surface_id="deck"
	f.elevation=2.0
	var enemy:=fig("thug",1,Vector2(11.5,10))
	enemy.surface_id="deck"
	enemy.elevation=2.0
	var c:=make_game(b,[f,enemy],Dice.new(19))
	c.state.active_id=f.id
	f.actions_left=2
	f.items.append({"gear":GearActions.CAPE,"gear_info":RedKingRewards.catalog()[GearActions.CAPE]})
	var dest:=b.floor_geometry().node("street",Vector2(13.5,10))
	var hp:=f.health
	check(not c.can_move())
	check(c.movement_options("gear_cape_move").jumps.has(dest))
	check(c.commit_movement("gear_cape_move",dest))
	check_eq(f.surface_id,"street")
	check_eq(f.health,hp)
	check_eq(f.moves_taken,1)
	check_eq(f.actions_left,1)
	check(not ActiveGear.ready(f,GearActions.CAPE))


func test_cape_ai_considers_aerial_escape_when_grounded_routes_are_trapped() -> void:
	var b:=make_board()
	b.floor_layout={"surfaces":[{"id":"west","rect":[2,2,2,2],"level":3},{"id":"east","rect":[4,0,8,6],"level":3}],"jumps":[{"from":["west",3.5,3],"to":["east",4.5,3]}]}
	var f:=fig("wizard",0,Vector2(3.5,3))
	f.surface_id="west"
	f.elevation=3.0
	var enemy:=fig("thug",1,Vector2(2.5,3))
	enemy.surface_id="west"
	enemy.elevation=3.0
	var c:=make_game(b,[f,enemy],Dice.new(19))
	c.state.active_id=f.id
	f.actions_left=2
	f.items.append({"gear":GearActions.CAPE,"gear_info":RedKingRewards.catalog()[GearActions.CAPE]})
	check(LayeredBattleBot._cape(c,f))
	check_eq(f.surface_id,"east")
	check(not Contact.in_combat(c.state.figures,f))
	check_eq(f.moves_taken,1)
	check_eq(f.actions_left,1)
	check(not ActiveGear.ready(f,GearActions.CAPE))
