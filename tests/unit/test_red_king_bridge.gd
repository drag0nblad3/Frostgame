extends TestCase


func _fixture() -> GameController:
	var packs := ContentProfile.registered().duplicate(true)
	packs["red_king"]["status"]="ready"
	var defs := FigureDb.load_files(FigureDb.FIGURES,FigureDb.WEAPONS,ContentProfile.new(["red_king"],packs))
	return GameController.new(ScenarioLoader.load_id("red_king_bridge",defs,terrain()),Dice.new(38))


func test_bridge_geometry_and_deployment() -> void:
	var c := _fixture()
	var s := c.state
	check_eq(s.board.size,Vector2(30,36))
	check_eq(s.side_figures(-1).size(),10)
	check_eq(s.board.void_regions.size(),2)
	check(s.board.can_stand(Vector2(15,33),Figure.BASE_RADIUS))
	check(not s.board.can_stand(Vector2(5,33),Figure.BASE_RADIUS))
	check(RedKingBridge.crosses_void(s.board,Vector2(12,29),Vector2(15,33)))
	check(not RedKingBridge.crosses_void(s.board,Vector2(15,29),Vector2(15,35)))
	check(ScenarioObjectives.exit_allowed(s,Vector2(15,35.5),0))
	check(not ScenarioObjectives.exit_allowed(s,Vector2(2,35.5),0))
	for f in s.figures:
		if f.side>=0:
			var corner := Vector2.ZERO if f.side==0 else Vector2(30,0)
			check(f.pos.distance_to(corner)<=4.0)


func test_veil_replacement_hrut_exemptions_and_save() -> void:
	var c := _fixture()
	var s := c.state
	var before := s.figures.size()
	RedKingBridge.replace_veil(c,5,6)
	check_eq(s.figures.size(),before+2)
	check_eq(s.board.boundaries.size(),1)
	check_eq(s.board.boundaries[0]["a"],Vector2(0,24))
	check_eq(s.board.boundaries[0]["b"],Vector2(30,30))
	var wizard := s.figures[0]
	var hrut: Figure=s.side_figures(-1)[0]
	var a := Vector2(15,22)
	var b := Vector2(15,29)
	check(BattleBoundary.blocks_segment(s.board.boundaries,a,b,"movement",wizard))
	check(BattleBoundary.blocks_segment(s.board.boundaries,a,b,"sight",wizard))
	check(not BattleBoundary.blocks_segment(s.board.boundaries,a,b,"movement",hrut))
	check(not BattleBoundary.blocks_segment(s.board.boundaries,a,b,"sight",hrut))
	wizard.spell_effects["plane_walk"]=true
	check(not BattleBoundary.blocks_segment(s.board.boundaries,a,b,"movement",wizard))
	check(BattleBoundary.blocks_segment(s.board.boundaries,a,b,"sight",wizard))
	RedKingBridge.replace_veil(c,2,3)
	check_eq(s.board.boundaries.size(),1)
	check_eq(s.board.boundaries[0]["a"],Vector2(0,6))
	var saved := BattleSnapshot.capture(c)
	var restored := BattleSnapshot.rebuild(saved,s.creature_db)
	check(restored!=null)
	if restored!=null:
		check_eq(restored.state.board.void_regions,s.board.void_regions)
		check_eq(restored.state.board.boundaries,s.board.boundaries)
