extends TestCase


func test_diagonal_prism_collision_is_not_its_bounding_box() -> void:
	var p:=ArchitecturePrism.from_dict({"profile":[[2,0,2],[5,0,5],[5.3,0,4.7],[2.3,0,1.7]],"extrusion":[0,3,0]})
	check(p.valid)
	check(p.overlaps(AABB(Vector3(3,0.1,3),Vector3(0.4,1.6,0.4))))
	check(not p.overlaps(AABB(Vector3(2.2,0.1,4.2),Vector3(0.4,1.6,0.4))))
	check(p.intersects_ray(Vector3(2,1,4),Vector3(4,1,2)))
	check(not p.intersects_ray(Vector3(2,4,4),Vector3(4,4,2)))
	check(p.mesh().get_surface_count()==1)


func test_sloping_roof_ray_and_clearance_share_geometry() -> void:
	var p:=ArchitecturePrism.from_dict({"profile":[[0,2,0],[4,4,0],[4,4,3],[0,2,3]],"extrusion":[0,0.2,0]})
	check(p.valid)
	check(p.intersects_ray(Vector3(2,0,1),Vector3(2,5,1)))
	check(not p.overlaps(AABB(Vector3(2,0.002,1),Vector3(0.4,1.6,0.4))))
	check(p.overlaps(AABB(Vector3(2,2.7,1),Vector3(0.4,1.6,0.4))))


func test_silent_tower_convex_ruins_have_real_geometry() -> void:
	var b:=BoardLoader.load_id("silent_tower",terrain())
	var l:=b.floor_geometry()
	check_eq(l.errors,[])
	check(l.convex_solids.size()>=20)
	# The centre of the arch is a passage; its masonry blocks higher rays.
	check(l.clearance(Vector3(6.5,0,28.9),Figure.BASE_RADIUS,1.6))
	check(LayeredSight.clear(l,Vector3(6.5,1.4,28.2),Vector3(6.5,1.4,29.5)))
	check(not LayeredSight.clear(l,Vector3(6.5,2.9,28.2),Vector3(6.5,2.9,29.5)))


func test_crumble_creates_real_breach_in_angled_wall() -> void:
	var entry: Dictionary={"profile":[[4,0,4],[8,0,8],[8.3,0,7.7],[4.3,0,3.7]],"extrusion":[0,3,0],"crumble_id":"test_wall"}
	var board:=BoardLoader.from_dict({"size":[16,16],"floor_layout":{"surfaces":[{"id":"street","rect":[0,0,16,16]}],"convex_solids":[entry]}},terrain())
	check_eq(board.pieces.size(),1)
	var f:=fig("wizard",0,Vector2(4,8))
	f.surface_id="street"
	var c:=make_game(board,[f],LoadedDice.new([20]))
	var center:=Vector3(6.15,0,5.85)
	check(not board.floor_geometry().clearance(center,0.25,1.6))
	c._magic.crumble.apply(board.pieces[0])
	check_eq(board.floor_geometry().convex_solids.size(),2)
	check(board.floor_geometry().clearance(center,0.25,1.6))
	check(LayeredSight.clear(board.floor_geometry(),center+Vector3(-2,1,2),center+Vector3(2,1,-2)))
	check(not LayeredSight.clear(board.floor_geometry(),Vector3(4,1,6),Vector3(6,1,4)))
