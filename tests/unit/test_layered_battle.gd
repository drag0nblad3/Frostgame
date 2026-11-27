extends TestCase


func test_extract_from_ground_edge_with_treasure() -> void:
	var c := LayeredBattle.create(db(),terrain(),17)
	var f := c.state.figure(2)
	c.state.active_id=f.id
	f.surface_id="street"
	f.pos=Vector2(1,8)
	f.elevation=0.0
	f.actions_left=2
	var token := c.state.treasure(0)
	f.treasure_id=token.id
	token.carrier_id=f.id
	var layout := FloorLayout.from_dict(c.state.board.floor_layout)
	var edge := layout.node("street",Vector2(0.5,8))
	check(c.floor_exit_nodes().has(edge))
	check(c.exit_on_floor(edge))
	check(f.exited)
	check_eq(token.secured_by,f.side)
	check_eq(f.treasure_id,-1)


func test_teleport_uses_floor_destination_and_existing_cast_roll() -> void:
	var c := LayeredBattle.create(db(),terrain(),17)
	var f := c.state.figure(1)
	c.state.active_id=f.id
	f.actions_left=2
	f.surface_id="landing"
	f.pos=Vector2(4.5,8)
	f.elevation=3.0
	var layout := FloorLayout.from_dict(c.state.board.floor_layout)
	var target := layout.node("upper",Vector2(6,8))
	check(LayeredMagic.can_teleport(c,target))
	check(not LayeredMagic.can_teleport(c,layout.node("street",Vector2(8,8))))
	c.dice=LoadedDice.new([20])
	check(c.teleport_on_floor(target))
	check(c.finish_cast(0))
	check_eq(f.surface_id,"upper")
	check_eq(f.pos,Vector2(6,8))
	check_eq(f.actions_left,0)
	check(f.magic_exhausted)


func test_bot_battle_keeps_surface_and_finishes() -> void:
	var c := LayeredBattle.create(db(),terrain(),17)
	var layout := FloorLayout.from_dict(c.state.board.floor_layout)
	var count := 0
	while not c.state.over and count<150:
		check(Bot.play_activation(c),"bot advances")
		count+=1
		for f in c.state.figures:
			if f.in_play():
				var n := layout.node(f.surface_id,f.pos)
				check(layout.standable(n))
				check(is_equal_approx(layout.height(n),f.elevation))
	check(c.state.over,"battle terminates")
	check(c.history.any(func(e: GameEvent) -> bool:return e.type=="layered_move"))
	check(c.history.any(func(e: GameEvent) -> bool:return e.type=="treasure_pickup"))


func test_dazzling_cape_layered_departure() -> void:
	var c := LayeredBattle.create(db(),terrain(),17)
	var f := c.state.figure(1)
	var t := c.state.figure(4)
	c.state.active_id=f.id
	f.actions_left=2
	t.pos=f.pos+Vector2.RIGHT
	t.surface_id=f.surface_id
	t.elevation=f.elevation
	f.items.append({"gear":GearActions.CAPE,"gear_info":RedKingRewards.catalog()[GearActions.CAPE]})
	var layout := FloorLayout.from_dict(c.state.board.floor_layout)
	var target := layout.node(f.surface_id,f.pos-Vector2.RIGHT)
	check(not c.can_move())
	check(LayeredMovement.reach(c,true).can_reach(target))
	check(LayeredMovement.move(c,target,true))
	check_eq(f.pos,Vector2(2,3))
	check_eq(f.actions_left,1)
	check(not ActiveGear.ready(f,GearActions.CAPE))
