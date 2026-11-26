extends TestCase


func test_leap_target_limits_and_cast_resolution() -> void:
	var c := LayeredBattle.create(db(),terrain(),17)
	var caster := c.state.figure(1)
	var t := c.state.figure(2)
	c.state.active_id=caster.id
	caster.actions_left=2
	caster.surface_id="street"
	caster.pos=Vector2(1,5)
	caster.elevation=0.0
	t.surface_id="street"
	t.pos=Vector2(1,8)
	t.elevation=0.0
	var layout := FloorLayout.from_dict(c.state.board.floor_layout)
	var grid := LayeredGrid.new(layout,t,c.state.figures)
	var target := layout.node("upper",Vector2(7,8))
	check(LayeredLeap.eligible(c,t))
	check(not LayeredLeap.path(c,t,target,layout,grid).is_empty(),"arc can clear western deck lip")
	t.treasure_id=0
	check(LayeredLeap.path(c,t,target,layout,grid).is_empty(),"treasure halves range")
	t.treasure_id=-1
	c.dice=LoadedDice.new([20])
	check(c.leap_on_floor(t.id,target))
	check(c.finish_cast(0))
	check_eq(t.surface_id,"upper")
	check_eq(t.elevation,3.0)
	check(t.magic_exhausted)
	check_eq(t.actions_left,0)
	check_eq(caster.actions_left,1)


func test_leap_cannot_go_through_solid_ceiling() -> void:
	var c := LayeredBattle.create(db(),terrain(),17)
	var f := c.state.figure(1)
	c.state.active_id=f.id
	f.actions_left=2
	f.surface_id="street"
	f.pos=Vector2(8,8)
	f.elevation=0.0
	var layout := FloorLayout.from_dict(c.state.board.floor_layout)
	var target := layout.node("upper",f.pos)
	check(LayeredLeap.path(c,f,target,layout,LayeredGrid.new(layout,f,c.state.figures)).is_empty())
