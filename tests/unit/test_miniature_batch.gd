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


func test_motion_profiles_and_leg_pivots() -> void:
	var defs := db()
	for id: String in ["wizard","knight","wolf","bear","ice_spider","ice_toad","wraith","giant_worm"]:
		var f := Figure.new(1,defs.get_def(id),0,Vector2.ZERO,defs.unarmed())
		var model := MiniatureFactory.create(f,Color.BLUE)
		var kind := MiniatureMotion.profile(f)
		MiniatureMotion.travel(model,kind,1.2,0.12)
		if id in ["wizard","knight","wolf","bear","ice_spider"]:
			check(model.has_node("Leg0"))
			var leg := model.get_node("Leg0") as Node3D
			check(absf(leg.rotation.x)>0.01)
		MiniatureMotion.action(model,kind,"attack",1.0,0.12,"staff")
		MiniatureMotion.action(model,kind,"attack",0.0,0.12,"staff")
		check(is_equal_approx(model.position.y,0.12))
		check(is_zero_approx(model.rotation.x))
		if model.has_node("Leg0"):
			check(is_zero_approx((model.get_node("Leg0") as Node3D).rotation.x))
		model.free()


func test_windup_and_running_keep_motion_visual_only() -> void:
	var defs := db()
	var f := Figure.new(2,defs.get_def("knight"),0,Vector2.ZERO,defs.unarmed())
	var model := MiniatureFactory.create(f,Color.BLUE)
	MiniatureMotion.action(model,"walk","attack",-0.45,0.12,"hand_weapon")
	check(model.rotation.x>0.0)
	MiniatureMotion.travel(model,"walk",1.0,0.12,false)
	var walk := absf((model.get_node("Leg0") as Node3D).rotation.x)
	MiniatureMotion.travel(model,"walk",1.0,0.12,true)
	check(absf((model.get_node("Leg0") as Node3D).rotation.x)>walk)
	model.free()


func test_nested_joint_preserves_geometry_and_weapon_attachment() -> void:
	var root := Node3D.new()
	var arm := MiniaturePose.arm(root,true)
	var elbow := MiniaturePose.joint(root,arm,"Elbow",Vector3(0.34,0.95,0.015))
	var first := root.get_child_count()
	var mesh := MiniatureFactory.box(root,Vector3(0.37,0.75,-0.09),Vector3.ONE*0.1,Color.RED)
	var before := mesh.position
	MiniaturePose.attach(root,elbow,first)
	check_eq(mesh.get_parent(),elbow)
	check((arm.transform*elbow.transform*mesh.position).is_equal_approx(before))
	elbow.rotation.x=-0.5
	check(not (arm.transform*elbow.transform*mesh.position).is_equal_approx(before))
	root.free()


func test_nested_hinges_bend_and_reset() -> void:
	var defs := db()
	for id: String in ["wizard","knight","wolf"]:
		var f := Figure.new(1,defs.get_def(id),0,Vector2.ZERO,defs.unarmed())
		var model := MiniatureFactory.create(f,Color.BLUE)
		check(model.has_node("Leg0/Knee"))
		MiniatureMotion.travel(model,MiniatureMotion.profile(f),1.2,0.12,true)
		if id!="wolf":
			check(model.has_node("RightArm/Elbow"))
			MiniatureMotion.action(model,"walk","attack",1.0,0.12,"staff")
			check(absf((model.get_node("RightArm/Elbow") as Node3D).rotation.x)>0.1)
		MiniatureMotion.reset(model)
		check(is_zero_approx((model.get_node("Leg0/Knee") as Node3D).rotation.x))
		model.free()


func test_tabletop_finish_covers_catalog_and_stays_batched() -> void:
	var defs := db()
	var data: Dictionary=JsonFile.read("res://data/figures.json")
	for id: String in data:
		if id.begins_with("_"):
			continue
		var f := Figure.new(12,defs.get_def(id),0,Vector2.ZERO,defs.unarmed())
		var model := MiniatureFactory.create(f,Color.BLUE)
		var meshes := model.find_children("*","MeshInstance3D",true,false)
		check(not meshes.is_empty())
		# Limit draw calls even for articulated and emissive figures.
		check(meshes.size()<100)
		model.free()


func test_higher_detail_increases_geometry_without_draw_call_growth() -> void:
	var defs := db()
	var f := Figure.new(2,defs.get_def("wizard"),0,Vector2.ZERO,defs.unarmed())
	var low := MiniatureFactory.create(f,Color.BLUE,"illusionist",0)
	var high := MiniatureFactory.create(f,Color.BLUE,"illusionist",2)
	var lv := 0
	var hv := 0
	for mesh: MeshInstance3D in low.find_children("*","MeshInstance3D",true,false):
		for i in mesh.mesh.get_surface_count():
			lv+=mesh.mesh.surface_get_array_len(i)
	for mesh: MeshInstance3D in high.find_children("*","MeshInstance3D",true,false):
		for i in mesh.mesh.get_surface_count():
			hv+=mesh.mesh.surface_get_array_len(i)
	check(hv>lv*1.3)
	check(high.find_children("*","MeshInstance3D",true,false).size()<=low.find_children("*","MeshInstance3D",true,false).size()+4)
	low.free()
	high.free()


func test_secondary_rigs_move_and_reset() -> void:
	var defs := db()
	for id: String in ["wizard","giant_worm","ice_toad"]:
		var f := Figure.new(3,defs.get_def(id),0,Vector2.ZERO,defs.unarmed())
		var model := MiniatureFactory.create(f,Color.BLUE,"illusionist",2)
		var part := "Cape" if id=="wizard" else ("Segment8" if id=="giant_worm" else "Leg1")
		check(model.has_node(part))
		MiniatureMotion.travel(model,MiniatureMotion.profile(f),1.3,0.12,true)
		check((model.get_node(part) as Node3D).rotation.length()>0.01)
		MiniatureMotion.reset(model)
		check((model.get_node(part) as Node3D).rotation.is_zero_approx())
		model.free()
