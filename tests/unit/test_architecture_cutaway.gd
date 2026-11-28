extends TestCase


func test_cutaway_only_near_intervening_geometry() -> void:
	var camera:=Vector3(5,5,-5)
	var focus:=Vector3(5,0.75,5)
	check(ArchitectureCutaway.blocks(camera,focus,AABB(Vector3(4,0,3),Vector3(2,3,0.5))))
	check(not ArchitectureCutaway.blocks(camera,focus,AABB(Vector3(8,0,3),Vector3(2,3,0.5))))
	check(not ArchitectureCutaway.blocks(camera,focus,AABB(Vector3(4,0,9),Vector3(2,3,0.5))))
	check(not ArchitectureCutaway.blocks(camera,focus,AABB(Vector3(4,-0.4,4),Vector3(2,0.4,2))))


func test_cutaway_does_not_use_convex_bounding_box_as_wall() -> void:
	var prism:=ArchitecturePrism.from_dict({"profile":[[2,0,2],[5,0,5],[5.2,0,4.8],[2.2,0,1.8]],"extrusion":[0,3,0]})
	check(prism.valid)
	check(not ArchitectureCutaway.blocks(Vector3(2.5,2,4.2),Vector3(2.5,1,5.5),prism.bounds,prism))
