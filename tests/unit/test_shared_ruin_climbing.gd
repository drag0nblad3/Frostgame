extends TestCase

func test_standard_ruin_maps_use_shared_profiled_supports() -> void:
	for id in ["treasure_skirmish","worm_hunts","genie_in_the_bottle"]:
		var s:=ScenarioLoader.load_id(id,db(),terrain())
		var l:=s.board.floor_geometry()
		check(l.errors.is_empty(),id+":"+str(l.errors))
		check(l.profiled_ground!=null,id)
		check(not s.scenario_data.has("support_errors"),id+":"+str(s.scenario_data.get("support_errors",[])))
		check(l.surfaces.any(func(x: FloorSurface) -> bool:return x.id.begins_with("climb:")),id+" climb nodes")
		for f in s.figures:
			var n:=l.node(f.surface_id,f.pos)
			check(l.standable(n),id+" figure support")
			if l.standable(n):
				check_eq(l.height(n),f.elevation)
		for t in s.treasures:
			check(not is_nan(TreasureRules.token_height(s,t)),id+" treasure support")
		check(StandardTreasurePlacement.prepare(s,Dice.new(19)),id+" placement")
		check_eq(s.treasures[0].pos,s.board.size*0.5,id+" centre")

func test_masonry_access_from_higher_bank() -> void:
	var b:=BoardLoader.from_dict({"shared_profiled_climbing":true,"size":[20,20],"pieces":[{"kind":"raised_ground","rect":[4,5,3,8],"level":1},{"kind":"tower","rect":[7,5,4,8]}]},terrain())
	var l:=b.floor_geometry()
	check(l.errors.is_empty(),str(l.errors))
	var start:=l.node("street",Vector2(6.5,8))
	var target:=l.node(b.pieces[1].dynamic_surface,Vector2(7.5,8))
	check_eq(l.height(start),1.0)
	check_eq(l.height(target),4.0)
	var route:=LayeredReach.search(LayeredGrid.new(l),start,7.1)
	check(route.can_reach(target))
	if route.can_reach(target):
		check(is_equal_approx(float(route.cost[target]),7.0))

func test_static_clearance_cache_keeps_different_radii_and_new_geometry_separate() -> void:
	var d: Dictionary={"surfaces":[{"id":"street","rect":[0,0,12,12],"level":0}]}
	var l:=FloorLayout.from_dict(d)
	var a:=l.node("street",Vector2(4,4))
	var b:=l.node("street",Vector2(4.5,4))
	check(l.standable(a))
	check(l.neighbor_clear(a,b))
	var edge:=l.node("street",Vector2(0.5,4))
	check(l.standable(edge))
	check(not l.standable(edge,0.75))
	d["solids"]=[[3.5,0,3.5,1,3,1]]
	var changed:=FloorLayout.from_dict(d)
	check(not changed.standable(a))
	check(not changed.neighbor_clear(a,b))
	check(l.standable(a))
