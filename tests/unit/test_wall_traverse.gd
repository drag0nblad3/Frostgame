extends TestCase

func _base() -> Dictionary:
	return {"auto_architecture_climbs":true,"surfaces":[{"id":"street","rect":[0,0,20,20],"level":0}]}

func test_narrow_wall_crossing_and_intermediate_positions() -> void:
	var d:=_base()
	d["solids"]=[[10,0,2,0.5,3,16]]
	var l:=FloorLayout.from_dict(d)
	check(l.errors.is_empty(),str(l.errors))
	var start:=l.node("street",Vector2(9.5,10.5))
	var finish:=l.node("street",Vector2(11,10.5))
	var grid:=LayeredGrid.new(l)
	var short:=LayeredReach.search(grid,start,4.0)
	check(not short.can_reach(finish))
	check(short.cost.keys().any(func(n: Vector3i) -> bool: return l.surface_id(n).begins_with("climb:auto:cross:") and l.height(n)>0.0))
	var full:=LayeredReach.search(grid,start,15.0)
	check(full.can_reach(finish))
	if full.can_reach(finish):
		check(is_equal_approx(float(full.cost[finish]),13.5))
		check(full.path_to(finish).any(func(n: Vector3i) -> bool: return l.surface_id(n).ends_with(":crest")))

func test_angled_wall_has_crossing() -> void:
	var d:=_base()
	# A 3-4-5 diagonal wall, 0.4 inches thick, with a vertical extrusion.
	d["convex_solids"]=[{"profile":[[8,0,5],[17,0,17],[16.68,0,17.24],[7.68,0,5.24]],"extrusion":[0,3,0]}]
	var l:=FloorLayout.from_dict(d)
	check(l.errors.is_empty(),str(l.errors))
	check(l.surfaces.any(func(s: FloorSurface) -> bool: return s.id.begins_with("climb:auto:cross:prism:") and s.id.ends_with(":crest")))

func test_overhead_slab_prevents_crossing() -> void:
	var d:=_base()
	d["solids"]=[[10,0,2,0.5,3,16],[8,3.1,1,5,0.4,18]]
	var l:=FloorLayout.from_dict(d)
	check(l.errors.is_empty(),str(l.errors))
	check(not l.surfaces.any(func(s: FloorSurface) -> bool: return s.id.ends_with(":crest")))
