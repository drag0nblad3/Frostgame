extends TestCase


func _preview_db() -> FigureDb:
	var packs := ContentProfile.registered().duplicate(true)
	packs["red_king"]["status"]="ready"
	return FigureDb.load_files(FigureDb.FIGURES,FigureDb.WEAPONS,ContentProfile.new(["red_king"],packs))


func test_expansion_bestiary_isolated() -> void:
	check(not db().figures.has("hrut_warrior"))
	var defs := _preview_db()
	check_eq(defs.get_def("hrut_warrior").health,12)
	check_eq(defs.get_def("hrut_longhammer").armour,13)
	check_eq(defs.get_def("red_king_key_master").will,10)
	check_eq(defs.get_def("mindshrike").health,1)
	check_eq(defs.get_def("nullman").fight,1)
	check_eq(defs.get_def("hrut_stinger").ranged_weapon().id,"crossbow")
	check(defs.available("foulhorn"))


func test_movement_senses_and_missile_resistance() -> void:
	var defs := _preview_db()
	var hrut := Figure.new(1,defs.get_def("hrut_warrior"),-1,Vector2(4,4),defs.unarmed())
	var wizard := fig("wizard",0,Vector2(14,4),2)
	var soldier := fig("thug",0,Vector2(8,4),3)
	check(CreatureSenses.detects(hrut,wizard))
	check(not CreatureSenses.detects(hrut,soldier))
	var burning := Figure.new(4,defs.get_def("burning_man"),-1,Vector2(8,4),defs.unarmed())
	check(burning.immune_to_poison())
	var archer := fig("archer",0,Vector2(4,4),5)
	var b := make_board()
	var result := Shooting.resolve_rolls(b,archer,burning,19,1)
	check_eq(result["dmg"],2)
	archer.spell_effects["enchant_weapon"]=true
	result=Shooting.resolve_rolls(b,archer,burning,19,1)
	check(int(result["dmg"])>2)
