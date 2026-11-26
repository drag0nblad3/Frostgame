extends TestCase


func _db_preview() -> FigureDb:
	var packs := ContentProfile.registered().duplicate(true)
	packs["red_king"]["status"]="ready"
	return FigureDb.load_files(FigureDb.FIGURES,FigureDb.WEAPONS,ContentProfile.new(["red_king"],packs))


func test_pain_blink_keeps_health_and_clamps_landing() -> void:
	var defs := _db_preview()
	var hrut := Figure.new(1,defs.get_def("hrut_warrior"),-1,Vector2(1,1),defs.unarmed())
	var wizard := fig("wizard",0,Vector2(10,10))
	var c := make_game(make_board(),[hrut,wizard],Dice.new(17))
	c._hurt(hrut,2,wizard,false)
	check_eq(hrut.health,10)
	check(hrut.pos.distance_to(Vector2(1,1))>0.1)
	check(c.state.board.can_stand(hrut.pos,Figure.BASE_RADIUS))
	check_eq(ForcedRelocation.destination(c.state,hrut,Vector2(-3,-5)),Vector2(0.5,0.5))


func test_combustion_replaces_definition_and_preserves_identity() -> void:
	var defs := _db_preview()
	var f := Figure.new(1,defs.get_def("blood_marked_berserker"),-1,Vector2(10,10),defs.unarmed())
	var c := make_game(make_board(),[f,fig("wizard",0,Vector2(20,20))],Dice.new(7))
	c.state.creature_db=defs
	f.health=3
	CreatureEffects.combust(c,f)
	check_eq(f.def.id,"burning_man")
	check_eq(f.health,10)
	check_eq(f.id,1)
	check_eq(f.pos,Vector2(10,10))
	check_eq(CreatureEffects.elemental_resistance(f),5)
