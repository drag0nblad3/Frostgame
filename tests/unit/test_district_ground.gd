extends TestCase


func test_street_ring_has_no_overlap_with_playable_floor() -> void:
	var board := BoardLoader.load_id("sunken_streets",TerrainDb.load_file())
	var interior := Rect2(Vector2.ZERO,board.size)
	var strips := DistrictGround.strips(board.size)
	check_eq(strips.size(),4)
	for rect in strips:
		check(not rect.intersects(interior))
	check_eq(strips[0].end.y,0.0)
	check_eq(strips[1].position.y,board.size.y)
	check_eq(strips[2].end.x,0.0)
	check_eq(strips[3].position.x,board.size.x)
	var floor_surface := StoneFinish.floor_surface(board,"sunken_streets")
	var root := DistrictGround.build(board,floor_surface.material_override)
	for child in root.get_children():
		var mesh: MeshInstance3D=child
		check(is_equal_approx(mesh.position.y,DistrictGround.STREET_Y))
		check_eq(mesh.material_override,floor_surface.material_override)
	check(board.ground_height_at(Vector2(18,18))<0.0)
	root.free()
	floor_surface.free()


func test_foreground_cutaway_preserves_distant_city() -> void:
	var root := Node3D.new()
	for side in 4:
		var node := Node3D.new()
		node.name="District%d"%side
		root.add_child(node)
	CityScenery.update_foreground(root,Vector3(18,4,-20),Vector2(36,36))
	check(not root.get_node("District0").visible)
	check(root.get_node("District2").visible)
	CityScenery.update_foreground(root,Vector3(18,40,-20),Vector2(36,36))
	check(root.get_node("District0").visible)
	root.free()
