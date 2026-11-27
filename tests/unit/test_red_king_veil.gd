extends TestCase


func _fixture() -> GameController:
	var packs := ContentProfile.registered().duplicate(true)
	packs["red_king"]["status"]="ready"
	var defs := FigureDb.load_files(FigureDb.FIGURES,FigureDb.WEAPONS,ContentProfile.new(["red_king"],packs))
	var s := ScenarioLoader.load_id("red_king_veil",defs,terrain())
	var c := GameController.new(s,Dice.new(38))
	RedKingVeil.prepare(c)
	return c


func test_veil_boundary_and_exits() -> void:
	var c := _fixture()
	var s := c.state
	check_eq(s.board.size,Vector2(24,36))
	check_eq(s.treasures.size(),3)
	check_eq(s.scenario_data["veil_slots"].size(),6)
	check(RedKingVeil.lethal(s,Vector2(12,11),Vector2(12,13)))
	check(not RedKingVeil.lethal(s,Vector2(12,8),Vector2(12,9)))
	check(not RedKingVeil.exit_allowed(s,Vector2(0.5,12),0))
	check(RedKingVeil.exit_allowed(s,Vector2(12,35.5),0))
	check(not RedKingVeil.exit_allowed(s,Vector2(12,35.5),1))
	RedKingVeil.advance(c,3)
	check_eq(s.scenario_data["veil_y"],19.0)
	check_eq(s.board.boundaries[0]["a"],Vector2(0,19))
	var f := s.figures[0]
	f.pos=Vector2(12,18)
	check(RedKingVeil.touch(c,f,Vector2(12,20)))
	check(not f.in_play())


func test_second_turn_arrivals_and_snapshot() -> void:
	var c := _fixture()
	var s := c.state
	s.turn=2
	s.phase=Phase.APPRENTICE
	RedKingVeil.before_phase(c)
	check_eq(RedKingVeil.waiting(s).size(),2)
	s.phase=Phase.SOLDIER
	RedKingVeil.before_phase(c)
	check_eq(RedKingVeil.waiting(s).size(),4)
	check_eq(s.side_figures(1).size(),6)
	var saved := BattleSnapshot.capture(c)
	check(not saved.is_empty())
	var restored := BattleSnapshot.rebuild(saved,s.creature_db)
	check(restored!=null)
	if restored!=null:
		check_eq(restored.state.scenario_data,s.scenario_data)
		check_eq(restored.state.board.boundaries,s.board.boundaries)


func test_veil_target_redirection() -> void:
	var c := _fixture()
	var s := c.state
	s.reaction_side=0
	RedKingVeil.end_turn(c)
	var choice: Dictionary=s.scenario_data.get("rk_end_choice",{})
	check_eq(choice.get("kind",""),"veil")
	if choice.is_empty():
		return
	var alternative := -1
	for id: int in choice["options"]:
		if id!=int(choice["target"]):
			alternative=id
			break
	check(alternative>=0)
	check(not RedKingVeil.answer_target(c,-1))
	check(RedKingVeil.answer_target(c,alternative))
	check(not s.scenario_data.has("rk_end_choice"))
	var found := false
	for event in c.history:
		if event.type=="fractured_reality" and event.data.get("id",-1)==alternative:
			found=bool(event.data.get("switched",false))
	check(found)
