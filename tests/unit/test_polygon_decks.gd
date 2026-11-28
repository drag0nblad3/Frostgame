extends TestCase


func test_polygon_deck_bounds_do_not_grant_false_support() -> void:
	var layout:=FloorLayout.from_dict({"surfaces":[{"id":"street","rect":[0,0,16,16]},{"id":"deck","rect":[4,4,4,4],"polygon":[[4,4],[8,4],[8,8],[6,8],[4,6]],"level":3}]})
	check_eq(layout.errors,[])
	check(layout.standable(layout.node("deck",Vector2(6,6))))
	check(not layout.standable(layout.node("deck",Vector2(4.5,7.5))))
	check(not LayeredSight.clear(layout,Vector3(6,1,6),Vector3(6,4,6)))
	check(LayeredSight.clear(layout,Vector3(4.5,1,7.5),Vector3(4.5,4,7.5)))
	check(layout.surfaces[1].contains(Vector2(4.5,5),0.4))
	check(not layout.surfaces[1].contains(Vector2(4.2,5),0.4))


func test_invalid_concave_deck_rejected() -> void:
	var layout:=FloorLayout.from_dict({"surfaces":[{"id":"deck","rect":[0,0,4,4],"polygon":[[0,0],[4,0],[2,2],[4,4],[0,4]],"level":3}]})
	check(not layout.errors.is_empty())


func test_free_rotation_of_convex_kit() -> void:
	var source: Dictionary={"floor_kits":{"wall":{"convex_solids":[{"profile":[[0,0,0],[4,0,0],[4,0,0.5],[0,0,0.5]],"extrusion":[0,2,0]}]}},"floor_assemblies":[{"kit":"wall","prefix":"diagonal:","origin":[5,5],"angle_degrees":30}]}
	var result:=FloorAssembly.expand(source)
	var layout:=FloorLayout.from_dict(result)
	check_eq(layout.errors,[])
	check_eq(layout.convex_solids.size(),1)
	var p:=layout.convex_solids[0]
	check(p.vertices[1].is_equal_approx(Vector3(5+4*cos(PI/6),0,7)))
	check(not p.overlaps(AABB(Vector3(5,0.1,7),Vector3(0.4,1.6,0.4))))


func test_silent_tower_ruins_have_cutaway_floor() -> void:
	var board:=BoardLoader.load_id("silent_tower",terrain())
	var layout:=board.floor_geometry()
	check_eq(layout.errors,[])
	var index:=layout.index_of("west_ruin:broken_gallery")
	check(index>=0)
	if index>=0:
		check_eq(layout.surfaces[index].polygon.size(),5)
		check(layout.standable(layout.node("west_ruin:broken_gallery",Vector2(7.5,9.5))))
		check(not layout.contains(layout.node("west_ruin:broken_gallery",Vector2(5.5,10))))
