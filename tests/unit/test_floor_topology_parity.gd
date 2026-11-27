extends TestCase


func test_wrap_route_keeps_elevation_and_cost() -> void:
	var b:=make_board([],Vector2(12,12))
	b.floor_layout={"surfaces":[{"id":"street","rect":[0,0,12,12],"level":0},{"id":"roof","rect":[2,0,8,12],"level":4}],"solids":[[2,3.8,0,8,0.2,12]]}
	b.wrap_short_edges=true
	var f:=fig("wizard",0,Vector2(5,0.5))
	f.surface_id="roof"
	f.elevation=4.0
	var c:=make_game(b,[f],LoadedDice.new([20]))
	c.state.active_id=f.id
	f.actions_left=2
	var layout:=b.floor_geometry()
	var n:=layout.node("roof",Vector2(5,11.5))
	var reach:=c.layered_reach()
	check(reach.can_reach(n))
	if reach.can_reach(n):
		check(is_equal_approx(float(reach.cost[n]),Figure.BASE_RADIUS))
		check(c.move_on_floor(n))
		check_eq(f.surface_id,"roof")
		check_eq(f.elevation,4.0)
		check_eq(f.pos,Vector2(5,11.5))


func test_spawn_occupancy_is_specific_to_reality() -> void:
	var b:=make_board([],Vector2(12,12))
	b.floor_layout={"surfaces":[{"id":"street","rect":[0,0,12,12],"level":0}]}
	var f:=fig("wizard",0,Vector2(5,5))
	f.surface_id="street"
	f.ring_side=0
	var c:=make_game(b,[f],LoadedDice.new([20]))
	var n:=b.floor_geometry().node("street",f.pos)
	check(not BattlePlacement.floor_open(c.state,n,null,Figure.BASE_RADIUS,1.6,true,null,0))
	check(BattlePlacement.floor_open(c.state,n,null,Figure.BASE_RADIUS,1.6,true,null,1))
