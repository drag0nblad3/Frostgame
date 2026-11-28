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
