extends TestCase


func preview_db() -> FigureDb:
	var packs := ContentProfile.registered().duplicate(true)
	packs["red_king"]["status"]="ready"
	return FigureDb.load_files(FigureDb.FIGURES,FigureDb.WEAPONS,ContentProfile.new(["red_king"],packs))


func test_setup_and_scent() -> void:
	var s := ScenarioLoader.load_id("red_king_squatter",preview_db(),terrain())
	var c := GameController.new(s,Dice.new(12))
	check_eq(s.treasures.size(),5)
	var troll := s.figures.back()
	check_eq(troll.def.id,"snow_troll")
	check(RedKingSquatter.dormant(c,troll))
	RedKingSquatter.awaken_near(c,Vector2(18,10),0)
	check(not RedKingSquatter.dormant(c,troll))
	check(s.scenario_data["troll_awake"])
	check(not LineOfSight.check(s.board,Vector2(18,5),Vector2(18,18)).clear)


func test_room_gate_and_reinforcement_limit() -> void:
	var s := ScenarioLoader.load_id("red_king_squatter",preview_db(),terrain())
	var c := GameController.new(s,Dice.new(17))
	var undead := Figure.new(100,s.creature_db.get_def("skeleton"),-1,Vector2(14,18),s.creature_db.unarmed())
	check(RedKingSquatter.permit_step(c,undead,Vector2(16,18)))
	check(s.scenario_data["squatter_passed"].has(100))
	var before := s.figures.size()
	for turn in range(1,8):
		s.turn=turn
		RedKingSquatter.end_turn(c)
	check_eq(s.figures.size(),before+6)
	var flags := BattleSnapshot.pack(s,["scenario_data"])
	check(BattleSnapshot.plain(flags))
