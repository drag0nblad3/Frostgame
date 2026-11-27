extends TestCase


func test_flat_and_single_floor_use_equal_route_costs() -> void:
	var b:=make_board([],Vector2(12,12))
	var flat:=MovePlanner.reach(MoveGrid.new(b),Vector2(4,4),4.0)
	b.floor_layout={"surfaces":[{"id":"ground","rect":[0,0,12,12],"level":0}]}
	var layout:=b.floor_geometry()
	var floor:=LayeredReach.search(LayeredGrid.new(layout),layout.node("ground",Vector2(4,4)),4.0)
	check_eq(flat.cost.size(),floor.cost.size())
	for n: Vector2i in flat.cost:
		var m:=Vector3i(n.x,n.y,0)
		check(floor.can_reach(m))
		if floor.can_reach(m):
			check(is_equal_approx(float(flat.cost[n]),float(floor.cost[m])))


func test_floor_geometry_cache_refreshes_when_layout_changes() -> void:
	var b:=make_board()
	b.floor_layout={"surfaces":[{"id":"street","rect":[0,0,36,36],"level":0}]}
	var before:=b.floor_geometry()
	check_eq(b.floor_geometry(),before)
	b.floor_layout["surfaces"].append({"id":"upper","rect":[6,6,6,6],"level":3})
	var after:=b.floor_geometry()
	check(after!=before)
	check_eq(after.surfaces.size(),2)
	check_eq(before.surfaces.size(),1)
