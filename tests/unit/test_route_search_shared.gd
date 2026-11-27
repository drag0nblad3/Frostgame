extends TestCase


func test_flat_and_single_floor_use_same_solver_and_axis_costs() -> void:
	var b:=make_board([],Vector2(12,12))
	var flat:=MovePlanner.reach(MoveGrid.new(b),Vector2(4,4),4.0)
	b.floor_layout={"surfaces":[{"id":"ground","rect":[0,0,12,12],"level":0}]}
	var layout:=b.floor_geometry()
	var floor:=LayeredReach.search(LayeredGrid.new(layout),layout.node("ground",Vector2(4,4)),4.0)
	# Exposed terrain preserves its historical direct off-lattice seed
	# edges; compare positions whose shortest route uses axis/diagonal
	# lattice steps, and enforce the same allowance on every endpoint.
	for at: Vector2 in [Vector2(7,4),Vector2(4,7),Vector2(2,2),Vector2(6,6),Vector2(4,0.5)]:
		var n:=MovePlanner.node_at(at)
		var m:=Vector3i(n.x,n.y,0)
		check(flat.can_reach(n) and floor.can_reach(m))
		if flat.can_reach(n) and floor.can_reach(m):
			check(is_equal_approx(float(flat.cost[n]),float(floor.cost[m])))
	for cost: float in floor.cost.values():
		check(cost<=4.001)
	for cost: float in flat.cost.values():
		check(cost<=4.001)


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
