extends TestCase


func _fixture() -> GameController:
	var packs := ContentProfile.registered().duplicate(true)
	packs["red_king"]["status"]="ready"
	var defs := FigureDb.load_files(FigureDb.FIGURES,FigureDb.WEAPONS,ContentProfile.new(["red_king"],packs))
	var s := ScenarioLoader.load_id("red_king_squatter",defs,terrain())
	s.scenario_data["reality_enabled"]=true
	return GameController.new(s,Dice.new(23))


func test_occurrence_and_single_use() -> void:
	check_eq(RealityCracks.threshold(1,2),20)
	check_eq(RealityCracks.threshold(2,2),18)
	check_eq(RealityCracks.threshold(2,3),19)
	var c := _fixture()
	c.state.turn=1
	RealityCracks.on_priority(c,[20,15])
	check(not c.state.scenario_data.get("reality_triggered",false))
	check(RealityCracks.apply(c,2))
	check_eq(c.state.board.boundaries.size(),1)
	RealityCracks.clear(c)
	check(c.state.board.boundaries.is_empty())
	check(not RealityCracks.apply(c,3))


func test_all_effects_dispatch_and_checkpoint() -> void:
	for effect in range(1,21):
		var c := _fixture()
		check(RealityCracks.apply(c,effect))
		check(c.state.scenario_data["reality_triggered"])
		var saved := BattleSnapshot.capture(c)
		check(not saved.is_empty())
		var restored := BattleSnapshot.rebuild(saved,c.state.creature_db)
		check(restored!=null)
		if restored!=null:
			check_eq(restored.state.scenario_data,c.state.scenario_data)
			check_eq(restored.state.board.boundaries,c.state.board.boundaries)
			check_eq(restored.state.board.low_gravity,c.state.board.low_gravity)


func test_sphere_cross_and_enneahedron() -> void:
	var c := _fixture()
	var b := c.state.board
	b.pieces.clear()
	b.invalidate_terrain()
	RealityCracks.apply(c,17)
	check(b.wrap_short_edges and b.wrap_long_edges)
	check(LineOfSight.check(b,Vector2(1,18),Vector2(35,18)).clear)
	check(not LineOfSight.check(b,Vector2(1,18),Vector2(10,18)).clear)
	check_eq(RealityCrackGeometry.sight_distance(b,Vector2(1,18),Vector2(35,18)),2.0)
	check(not ScenarioObjectives.exit_allowed(c.state,Vector2(0.5,18)))
	check(BoardTopology.destinations(b,Vector2i(1,20)).has(Vector2i(71,20)))
	RealityCracks.clear(c)
	check(not b.wrap_short_edges and not b.wrap_long_edges)
	c.state.scenario_data.erase("reality_triggered")
	RealityCracks.apply(c,18)
	b.reality_cross=0
	check_eq(RealityCrackGeometry.cross_relation(b,Vector2(24,8),Vector2(8,24)),1)
	check(LineOfSight.check(b,Vector2(24,8),Vector2(8,24)).clear)
	check(not LineOfSight.check(b,Vector2(8,8),Vector2(24,8)).clear)
	RealityCracks.clear(c)
	c.state.scenario_data.erase("reality_triggered")
	RealityCracks.apply(c,20)
	check_eq(b.boundaries.size(),4)
	check(BattleBoundary.blocks_end(b.boundaries,Vector2(12,6)))
	check(not BattleBoundary.blocks_segment(b.boundaries,Vector2(10,6),Vector2(14,6),"movement"))
	check(BattleBoundary.blocks_segment(b.boundaries,Vector2(10,6),Vector2(14,6),"sight"))


func test_secret_exchange_player_selection() -> void:
	var c := _fixture()
	var s := c.state
	s.reaction_side=0
	s.order.assign([0,1])
	check(RealityCracks.apply(c,19))
	RealityCracks.on_end_turn(c)
	var choice: Dictionary=s.scenario_data.get("rk_end_choice",{})
	check_eq(choice.get("kind",""),"exchange")
	if choice.is_empty():
		return
	check(c.awaiting_reaction())
	var id := int(choice["options"][0])
	var rival := s.figure(int(choice["committed"][0]))
	var previous := rival.pos
	check(not RealityCracks.answer_exchange(c,-1))
	check(RealityCracks.answer_exchange(c,id))
	check_eq(s.figure(id).pos,previous)
	check(not s.scenario_data.has("rk_end_choice"))


func test_shifting_ruins_player_choices() -> void:
	var c := _fixture()
	var s := c.state
	s.reaction_side=0
	s.order.assign([0,1])
	check(RealityCracks.apply(c,15))
	var choice: Dictionary=s.scenario_data.get("rk_priority_choice",{})
	check_eq(choice.get("kind",""),"ruins")
	if choice.is_empty():
		return
	var first := int(choice["options"][0])
	var points := RealityCrackTerrain.shift_points(c,first)
	check(not points.is_empty())
	if points.is_empty():
		return
	check(not RealityCrackTerrain.answer_shift(c,first,Vector2(-1,-1)))
	var saved := BattleSnapshot.capture(c)
	var restored := BattleSnapshot.rebuild(saved,s.creature_db)
	check(restored!=null)
	if restored==null:
		return
	check(RealityCrackTerrain.answer_shift(restored,first,points[0]))
	check_eq(restored.state.board.pieces[first].rect.get_center(),points[0])
	var next: Dictionary=restored.state.scenario_data.get("rk_priority_choice",{})
	if not next.is_empty():
		check(not next["options"].has(first))
		var second := int(next["options"][0])
		var destinations := RealityCrackTerrain.shift_points(restored,second)
		check(RealityCrackTerrain.answer_shift(restored,second,destinations[0]))
	check(not restored.state.scenario_data.has("rk_priority_choice"))


func test_convergence_placement_and_checkpoint() -> void:
	var c := _fixture()
	var s := c.state
	s.board.pieces.clear()
	s.board.invalidate_terrain()
	var anchor := s.figures[0]
	var f := s.figures[1]
	anchor.pos=s.board.size*0.5
	anchor.elevation=0
	f.pos=anchor.pos+Vector2(0,4)
	f.elevation=0
	s.scenario_data["rk_convergence"]={"remaining":0,"moved":[anchor.id]}
	s.scenario_data["rk_priority_choice"]={"kind":"convergence","id":f.id}
	var points := RealityConvergence.points(c)
	check(not points.is_empty())
	if points.is_empty():
		return
	check(not RealityConvergence.answer(c,Vector2(-1,-1)))
	for at in points:
		check(Contact.touching(anchor.pos,at))
		check(at.distance_to(anchor.pos)>=Contact.OVERLAP)
	var saved := BattleSnapshot.capture(c)
	var restored := BattleSnapshot.rebuild(saved,s.creature_db)
	check(restored!=null)
	if restored==null:
		return
	check(RealityConvergence.answer(restored,points[0]))
	check_eq(restored.state.figure(f.id).pos,points[0])
	check(not restored.state.scenario_data.has("rk_priority_choice"))


func test_lightning_front_waits_for_absorption() -> void:
	var c := _fixture()
	var s := c.state
	var f := s.figures[0]
	s.reaction_side=f.side
	s.order.assign([0,1])
	for other in s.figures:
		other.pos=Vector2(2,2)
	f.pos=s.board.size*0.5
	f.items.append({"gear":RedKingElemental.AMULET})
	var hp := f.health
	# Directly exercise the same priority queue with deterministic damage.
	s.scenario_data["rk_lightning_queue"]=[]
	s.scenario_data["rk_lightning_absorb"]={"target":f.id,"damage":5}
	check(c.awaiting_reaction())
	check_eq(f.health,hp)
	check(c.answer_elemental_combat(false))
	check_eq(f.health,hp-4)
	check(ActiveGear.ready(f,RedKingElemental.AMULET))
	check(not s.scenario_data.has("rk_lightning_queue"))


func test_last_figure_can_decline_random_exchange() -> void:
	var c := _fixture()
	var s := c.state
	s.reaction_side=0
	s.order.assign([0,1])
	var f := s.side_figures(0)[0]
	for other in s.side_figures(0):
		if other!=f:
			other.out_of_action=true
	var before := f.pos
	check(RealityCracks.apply(c,11))
	RealityCracks.on_end_turn(c)
	check_eq(s.scenario_data.get("rk_end_choice",{}).get("kind",""),"random_exchange_single")
	check(RealityCracks.answer_exchange(c,-1))
	check_eq(f.pos,before)
	check(not s.scenario_data.has("rk_end_choice"))
