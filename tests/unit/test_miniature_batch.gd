extends TestCase


func test_batch_preserves_bounds_and_combines_geometry() -> void:
	var root := Node3D.new()
	MiniatureFactory.box(root, Vector3(1, 0, 0), Vector3.ONE, Color.RED)
	MiniatureFactory.box(root, Vector3(-1, 0, 0), Vector3.ONE, Color.BLUE)
	MiniatureBatch.bake(root)
	check_eq(root.get_child_count(), 1)
	var mesh: MeshInstance3D = root.get_child(0)
	check(is_equal_approx(mesh.mesh.get_aabb().size.x, 3.0))
	check_eq(mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR].size(), mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size())
	root.free()


func test_wizard_arms_keep_independent_pose() -> void:
	var defs := db()
	var f := Figure.new(1, defs.get_def("wizard"), 0, Vector2.ZERO, defs.unarmed())
	var model := MiniatureFactory.create(f, Color.BLUE)
	var right := model.get_node_or_null("RightArm") as Node3D
	var left := model.get_node_or_null("LeftArm") as Node3D
	check(right != null and left != null)
	if right != null and left != null:
		MiniaturePose.arms(model, -0.5, 0.25)
		check(is_equal_approx(right.rotation.x, -0.5))
		check(is_equal_approx(left.rotation.x, 0.25))
		check(right.get_child_count() > 0)
	model.free()
