extends TestCase


func test_ruins_keep_logical_bounding_box() -> void:
	var mesh := RuinedMesh.build(Vector2(6,4),4.0,17)
	var bounds := mesh.get_aabb()
	check(is_equal_approx(bounds.size.x,6.0))
	check(is_equal_approx(bounds.size.y,4.0))
	check(is_equal_approx(bounds.size.z,4.0))


func test_outskirts_do_not_reach_playing_surface() -> void:
	var board := Board.new()
	board.size = Vector2(36,36)
	var city := CityScenery.build(board,"treasure_skirmish")
	check(city.get_child_count()>0)
	for child in city.get_children():
		if child is MeshInstance3D:
			check((child.transform*child.mesh.get_aabb()).end.y<0.0)
	city.free()
	var indoor := CityScenery.build(board,"underground_library")
	check_eq(indoor.get_child_count(),0)
	indoor.free()
