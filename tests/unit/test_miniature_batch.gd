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


func test_refined_soldiers_keep_equipment_pivots() -> void:
	var defs := db()
	for id: String in ["thug","thief","archer","crossbowman","infantryman","man_at_arms","treasure_hunter","knight","barbarian","ranger","marksman","tracker","templar","apothecary","vampire"]:
		var f := Figure.new(7,defs.get_def(id),0,Vector2.ZERO,defs.unarmed())
		var model := MiniatureFactory.create(f,Color.BLUE)
		check(model.has_node("RightArm") and model.has_node("LeftArm"))
		check(not model.get_node("RightArm").get_children().is_empty())
		check(not model.get_node("LeftArm").get_children().is_empty())
		MiniaturePose.arms(model,-0.3,0.2)
		model.free()


func test_refined_beasts_and_constructs_have_batched_meshes() -> void:
	var defs := db()
	for id: String in ["war_hound","wild_dog","wolf","bear","boar","giant_rat","snow_leopard","small_construct","medium_construct","large_construct"]:
		var f := Figure.new(8,defs.get_def(id),0,Vector2.ZERO,defs.unarmed())
		var model := MiniatureFactory.create(f,Color.RED)
		check(not model.find_children("*","MeshInstance3D",true,false).is_empty())
		model.free()


func test_supernatural_models_keep_articulated_arms() -> void:
	var defs := db()
	for id: String in ["skeleton","armoured_skeleton","skeleton_archer","ghoul","zombie","wraith","genie","imp","minor_demon","major_demon","white_gorilla","werewolf","snow_troll","frost_giant"]:
		var f := Figure.new(9,defs.get_def(id),-1,Vector2.ZERO,defs.unarmed())
		var model := MiniatureFactory.create(f,Color.PURPLE)
		check(model.has_node("RightArm") and model.has_node("LeftArm"))
		check(not model.get_node("RightArm").get_children().is_empty())
		check(not model.get_node("LeftArm").get_children().is_empty())
		MiniaturePose.arms(model,-0.4,0.2)
		model.free()


func test_other_magical_creatures_bake() -> void:
	var defs := db()
	for id: String in ["ice_spider","ice_toad","giant_worm","animated_skull"]:
		var f := Figure.new(10,defs.get_def(id),-1,Vector2.ZERO,defs.unarmed())
		var model := MiniatureFactory.create(f,Color.PURPLE)
		check(not model.find_children("*","MeshInstance3D",true,false).is_empty())
		model.free()
