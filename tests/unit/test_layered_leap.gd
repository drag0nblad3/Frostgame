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


func test_shared_leap_availability_matches_floor_destinations() -> void:
	var c:=LayeredBattle.create(db(),terrain(),17)
	var f:=c.state.figure(1)
	var t:=c.state.figure(2)
	c.state.active_id=f.id
	f.actions_left=2
	f.surface_id="street"
	f.pos=Vector2(1,5)
	f.elevation=0.0
	t.surface_id="street"
	t.pos=Vector2(1,8)
	t.elevation=0.0
	var layout:=c.state.board.floor_geometry()
	var index:=layout.index_of("upper")
	var target:=layout.node("upper",Vector2(7,8))
	check(c.can_cast("leap",t.id))
	check(LayeredLeap.points(c,t,false,index).has(target))
	check_eq(t.pos,Vector2(1,8))
	t.treasure_id=0
	check(not LayeredLeap.points(c,t,false,index).has(target))
	t.treasure_id=-1
	t.spell_effects["plane_walk"]=true
	check(not c.can_cast("leap",t.id))
	check(LayeredLeap.points(c,t).is_empty())
	t.spell_effects.erase("plane_walk")
	t.ring_side=1 if f.ring_side!=1 else 0
	check(not c.can_cast("leap",t.id))


func test_leap_cannot_cross_dimensional_void() -> void:
	var b:=make_board()
	b.floor_layout={"surfaces":[{"id":"street","rect":[0,0,36,36],"level":0}]}
	b.void_regions.append(Rect2(7,0,1,36))
	var f:=fig("wizard",0,Vector2(5,5))
	f.surface_id="street"
	var c:=make_game(b,[f],Dice.new(19))
	c.state.active_id=f.id
	f.actions_left=2
	var layout:=b.floor_geometry()
	var n:=layout.node("street",Vector2(9,5))
	var grid:=LayeredGrid.new(layout,f,c.state.figures)
	check(LayeredLeap.path(c,f,n,layout,grid).is_empty())
