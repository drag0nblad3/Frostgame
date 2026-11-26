extends TestCase


func test_bestiary_models_bake_and_have_geometry() -> void:
	var defs := db()
	for id: String in ["imp", "minor_demon", "major_demon", "small_construct", "medium_construct", "large_construct", "ghoul", "zombie", "animated_skull", "giant_worm"]:
		var f := Figure.new(1, defs.get_def(id), -1, Vector2.ZERO, defs.unarmed())
		var model := MiniatureFactory.create(f, Color.BLUE)
		check(not model.find_children("*", "MeshInstance3D", true, false).is_empty())
		check(model.get_child_count() < 12)
		model.free()


func test_construct_sizes_and_independent_arms() -> void:
	var defs := db()
	var small := MiniatureFactory.create(Figure.new(1, defs.get_def("small_construct"), -1, Vector2.ZERO, defs.unarmed()), Color.BLUE)
	var big := MiniatureFactory.create(Figure.new(2, defs.get_def("large_construct"), -1, Vector2.ZERO, defs.unarmed()), Color.BLUE)
	check(big.scale.y > small.scale.y)
	var arm := big.get_node_or_null("RightArm") as Node3D
	check(arm != null)
	if arm != null:
		MiniaturePose.arms(big, -0.5, 0.25)
		check(is_equal_approx(arm.rotation.x, -0.5))
	small.free()
	big.free()
