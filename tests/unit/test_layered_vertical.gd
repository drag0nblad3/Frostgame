extends TestCase


func _gate() -> GameController:
	return LayeredBattle.create(db(),terrain(),17)


func test_partial_climb_and_restore() -> void:
	var c := _gate()
	var f := c.state.figure(2)
	c.state.active_id=f.id
	f.surface_id="street"
	f.pos=Vector2(13.5,8)
	f.elevation=0.0
	f.actions_left=2
	f.moves_taken=1
	var layout := FloorLayout.from_dict(c.state.board.floor_layout)
	check(layout.errors.is_empty(),str(layout.errors))
	var hanging := layout.node("climb:east_wall:1",f.pos)
	check(c.layered_reach().can_reach(hanging))
	check(c.move_on_floor(hanging))
	check_eq(f.elevation,1.0)
	check_eq(f.actions_left,1)
	var restored := BattleSnapshot.rebuild(BattleSnapshot.capture(c),db())
	check(restored!=null)
	if restored!=null:
		check_eq(restored.state.active().surface_id,"climb:east_wall:1")
		check_eq(restored.state.active().elevation,1.0)
	f.actions_left=2
	f.moves_taken=0
	check(c.move_on_floor(layout.node("upper",Vector2(12.5,8))))
	check_eq(f.elevation,3.0)


func test_push_over_ledge_damages_and_changes_floor() -> void:
	var c := _gate()
	var a := c.state.figure(2)
	var b := c.state.figure(5)
	a.surface_id="upper"
	a.pos=Vector2(11.5,8)
	a.elevation=3.0
	b.surface_id="upper"
	b.pos=Vector2(12.5,8)
	b.elevation=3.0
	c.state.push_winner=a.id
	c.state.push_loser=b.id
	var hp := b.health
	check(c.can_push(false))
	check(c.resolve_push(false))
	check_eq(b.surface_id,"street")
	check_eq(b.elevation,0.0)
	check_eq(b.health,hp-ElevationRules.fall_damage(3.0))


func test_jump_needs_runup_and_consumes_movement() -> void:
	var b := make_board()
	b.floor_layout={"surfaces":[{"id":"west","rect":[0,0,6,6],"level":3},{"id":"east","rect":[7,0,6,6],"level":3}],"jumps":[{"from":["west",5.5,3],"to":["east",7.5,3]}]}
	var f := fig("thug",0,Vector2(3.5,3))
	f.surface_id="west"
	f.elevation=3.0
	var c := make_game(b,[f],Dice.new(1))
	c.state.active_id=1
	f.actions_left=2
	var layout := FloorLayout.from_dict(b.floor_layout)
	var target := layout.node("east",Vector2(7.5,3))
	check(LayeredJump.plans(c).has(target))
	f.pos=Vector2(4.5,3)
	check(not LayeredJump.plans(c).has(target))
	f.pos=Vector2(3.5,3)
	check(c.jump_on_floor(target))
	check_eq(f.surface_id,"east")
	check_eq(f.actions_left,1)
	check_eq(f.moves_taken,1)
