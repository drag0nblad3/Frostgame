extends TestCase


func test_school_catalog_has_ten_visual_palettes() -> void:
	var schools: Dictionary = JsonFile.read("res://data/schools.json")
	check_eq(SchoolArt.PALETTES.size(), schools.size())
	var defs := db()
	for id: String in schools:
		check(SchoolArt.PALETTES.has(id))
		var f := Figure.new(1,defs.get_def("wizard"),0,Vector2.ZERO,defs.unarmed())
		var model := MiniatureFactory.create(f,Color.BLUE,id)
		check(not model.find_children("*","MeshInstance3D",true,false).is_empty())
		model.free()


func test_school_metadata_survives_checkpoint() -> void:
	var s := ScenarioLoader.load_id("treasure_skirmish",db(),terrain())
	check_eq(s.side_schools.get(0),"elementalist")
	check_eq(s.side_schools.get(1),"necromancer")
	var c := GameController.new(s,Dice.new(7))
	var restored := BattleSnapshot.rebuild(BattleSnapshot.capture(c),db())
	check(restored != null)
	if restored != null:
		check_eq(SchoolArt.of_figure(restored.state.figure(1)),"elementalist")


func test_wizard_cloth_varies_by_identity_not_school() -> void:
	var defs := db()
	var f := Figure.new(1,defs.get_def("wizard"),0,Vector2.ZERO,defs.unarmed())
	var other := Figure.new(2,defs.get_def("wizard"),0,Vector2.ZERO,defs.unarmed())
	var coat := WizardSculpt.cloth(f)
	check(coat!=WizardSculpt.cloth(other))
	f.campaign_id=99
	other.campaign_id=99
	check_eq(WizardSculpt.cloth(f),WizardSculpt.cloth(other))
	var s := GameState.new()
	f.battle_ref=weakref(s)
	s.side_schools[0]="witch"
	var before := WizardSculpt.cloth(f)
	s.side_schools[0]="elementalist"
	check_eq(WizardSculpt.cloth(f),before)


func test_every_school_preserves_articulated_wizard_and_apprentice() -> void:
	var defs := db()
	for school: String in SchoolArt.PALETTES:
		for role: String in ["wizard","apprentice"]:
			var f := Figure.new(3,defs.get_def(role),0,Vector2.ZERO,defs.unarmed())
			var model := MiniatureFactory.create(f,Color.BLUE,school)
			check(model.has_node("RightArm"))
			check(model.has_node("LeftArm"))
			check(not model.get_node("RightArm").get_children().is_empty())
			MiniaturePose.arms(model,0.2,-0.4)
			model.free()


func test_wizard_livery_survives_mesh_batching() -> void:
	var defs := db()
	var f := Figure.new(3,defs.get_def("wizard"),0,Vector2.ZERO,defs.unarmed())
	var blue := MiniatureFactory.create(f,Color.BLUE,"witch")
	var red := MiniatureFactory.create(f,Color.RED,"witch")
	check(_has_pigment(blue,WizardLivery.color(Color.BLUE)))
	check(_has_pigment(red,WizardLivery.color(Color.RED)))
	check(not _has_pigment(red,WizardLivery.color(Color.BLUE)))
	check(_has_pigment(blue,WizardSculpt.cloth(f)))
	check(_has_pigment(red,WizardSculpt.cloth(f)))
	blue.free()
	red.free()


func _has_pigment(root: Node3D,color: Color) -> bool:
	for node in root.find_children("*","MeshInstance3D",true,false):
		var mesh: Mesh = node.mesh
		for i in mesh.get_surface_count():
			var colors: Variant=mesh.surface_get_arrays(i)[Mesh.ARRAY_COLOR]
			if colors==null:
				continue
			for tint: Color in colors:
				if absf(tint.r-color.r)+absf(tint.g-color.g)+absf(tint.b-color.b)<0.025:
					return true
	return false
