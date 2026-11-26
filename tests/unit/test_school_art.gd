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
