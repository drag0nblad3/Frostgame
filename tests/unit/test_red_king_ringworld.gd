extends TestCase


func _fixture() -> GameController:
	var packs := ContentProfile.registered().duplicate(true)
	packs["red_king"]["status"]="ready"
	var defs := FigureDb.load_files(FigureDb.FIGURES,FigureDb.WEAPONS,ContentProfile.new(["red_king"],packs))
	return GameController.new(ScenarioLoader.load_id("red_king_ringworld",defs,terrain()),Dice.new(38))


func test_planes_and_wrap() -> void:
	var c := _fixture()
	var s := c.state
	check_eq(RedKingRingworld.remaining(s),4)
	check_eq(s.side_figures(-1).size(),20)
	check_eq(s.treasures.size(),5)
	check(s.board.wrap_short_edges)
	for token in s.treasures:
		check(token.central)
	var a := s.figures[0]
	var b := s.figures[1]
	a.pos=Vector2(15,18)
	b.pos=Vector2(15,18)
	a.ring_side=0
	b.ring_side=1
	check(not Contact.figures_touch(a,b))
	check(not LineOfSight.check_figures(s.board,a,b).clear)
	check_eq(BoardTopology.destinations(s.board,Vector2i(20,1)),[Vector2i(20,71)])
	check_eq(BoardTopology.sources(s.board,Vector2i(20,71)),[Vector2i(20,1)])
	check(not ScenarioObjectives.exit_allowed(s,Vector2(10,0.5),0))
	var saved := BattleSnapshot.capture(c)
	var restored := BattleSnapshot.rebuild(saved,s.creature_db)
	check(restored!=null)
	if restored!=null:
		check_eq(restored.state.figures[1].ring_side,1)
		check_eq(restored.state.treasures[0].ring_side,1)
		check(restored.state.board.wrap_short_edges)


func test_escape_and_finale() -> void:
	var c := _fixture()
	var s := c.state
	var a := s.figures[0]
	var key: Figure=null
	for f in s.figures:
		if RedKingRingworld.key_master(f):
			key=f
			break
	a.ring_side=key.ring_side
	a.pos=key.pos+Vector2.RIGHT
	s.active_id=a.id
	check(RedKingRingworld.can_escape(c,a))
	check(RedKingRingworld.escape(c,a))
	check(a.exited)
	var b := s.figures[1]
	for f in s.figures:
		if RedKingRingworld.key_master(f):
			c._hurt(f,f.health,b,false)
	check(RedKingRingworld.check_end(c))
	check(s.scenario_data["ring_success"])
	check(b.out_of_action)
	check(b.spell_effects.has("ring_left_behind"))
	check(not a.out_of_action)
	check_eq(RedKingRingworld.reinforcements(20)["types"].size(),5)
