extends TestCase


func _fixture() -> GameController:
	var packs := ContentProfile.registered().duplicate(true)
	packs["red_king"]["status"]="ready"
	var defs := FigureDb.load_files(FigureDb.FIGURES,FigureDb.WEAPONS,ContentProfile.new(["red_king"],packs))
	return GameController.new(ScenarioLoader.load_id("red_king_hill",defs,terrain()),Dice.new(38))


func test_guarded_treasure_and_priority_crack() -> void:
	var c := _fixture()
	var s := c.state
	check_eq(s.treasures.size(),5)
	check_eq(s.side_figures(-1).size(),5)
	check(RedKingHill.guarded(s,s.treasures[0]))
	var herald: Figure=s.side_figures(-1)[0]
	for f in s.figures:
		if RedKingHill.is_herald(s,f):
			herald=f
	check(RedKingHill.airborne(herald))
	herald.pos=Vector2(21,18)
	check(not RedKingHill.guarded(s,s.treasures[0]))
	herald.pos=Vector2(18,18)
	s.turn=1
	RedKingHill.priority(c,[15,11])
	check(not RedKingHill.cracked(s))
	RedKingHill.priority(c,[16,11])
	check(RedKingHill.cracked(s))
	check_eq(s.board.boundaries.size(),2)
	check(BattleBoundary.blocks_segment(s.board.boundaries,Vector2(18,10),Vector2(26,18),"sight"))
	check(not BattleBoundary.blocks_segment(s.board.boundaries,Vector2(18,17),Vector2(26,18),"sight"))
	check(not BattleBoundary.blocks_segment(s.board.boundaries,Vector2(18,10),Vector2(26,18),"movement"))
	var saved := BattleSnapshot.capture(c)
	var restored := BattleSnapshot.rebuild(saved,s.creature_db)
	check(restored!=null)
	if restored!=null:
		check(RedKingHill.cracked(restored.state))
		check_eq(restored.state.board.boundaries,s.board.boundaries)


func test_downhill_motion_and_airborne_immunity() -> void:
	var c := _fixture()
	var s := c.state
	RedKingHill.transform(c)
	s.board.pieces.clear()
	s.board.floor_layout.erase("walls")
	s.board.invalidate_terrain()
	var f := s.figures[0]
	f.pos=Vector2(18,10)
	for other in s.figures:
		if other!=f:
			other.pos=Vector2(30,30)
	check_eq(RedKingHill.downhill(s,f.pos),Vector2.UP)
	RedKingHill.fall(c,f)
	check_eq(f.pos,Vector2(18,4))
	for other in s.figures:
		if other.def.id=="hrut_stinger":
			var old := other.pos
			RedKingHill.fall(c,other)
			check_eq(other.pos,old)
			break


func test_player_selects_pyramid_slope() -> void:
	var c := _fixture()
	var s := c.state
	s.reaction_side=0
	s.order.assign([0,1])
	var f := s.figures[0]
	f.pos=Vector2(10,10)
	s.board.pieces.clear()
	s.board.floor_layout.erase("walls")
	s.board.invalidate_terrain()
	RedKingHill.transform(c)
	var choice: Dictionary=s.scenario_data.get("rk_priority_choice",{})
	check_eq(choice.get("kind",""),"hill_seam")
	if choice.is_empty():
		return
	var target := s.figure(int(choice["id"]))
	var points := RedKingHill.seam_points(c,target)
	check(points.size()>1)
	check(not RedKingHill.answer_seam(c,Vector2(-1,-1)))
	check(RedKingHill.answer_seam(c,points[0]))
	check(not RedKingHill._straddles(s,target.pos))
