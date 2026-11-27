extends TestCase


func _fixture() -> GameController:
	var packs := ContentProfile.registered().duplicate(true)
	packs["red_king"]["status"]="ready"
	var defs := FigureDb.load_files(FigureDb.FIGURES,FigureDb.WEAPONS,ContentProfile.new(["red_king"],packs))
	return GameController.new(ScenarioLoader.load_id("red_king_tethers",defs,terrain()),Dice.new(38))


func test_pylon_objectives_and_restoration() -> void:
	var c := _fixture()
	var s := c.state
	check_eq(RedKingTethers.remaining(s),5)
	check_eq(s.side_figures(-1).size(),15)
	for t in s.treasures:
		check(not t.on_ground())
	RedKingTethers.transform(c)
	check_eq(s.board.edge_links.size(),6)
	check(not ScenarioObjectives.exit_allowed(s,Vector2(6,0.5),0))
	var attacker := s.figures[0]
	for f in s.figures:
		if RedKingTethers.pylon(f):
			check_eq(Melee.fight_mod(s.figures,f,attacker),0)
			c._hurt(f,1,attacker)
	check_eq(RedKingTethers.remaining(s),0)
	check(s.board.edge_links.is_empty())
	check(s.board.boundaries.is_empty())
	for t in s.treasures:
		check(t.on_ground())
		check_eq(t.bonus_gold,20)


func test_topology_movement_and_checkpoint() -> void:
	var c := _fixture()
	var s := c.state
	s.order.assign([0,1])
	RedKingTethers.transform(c)
	s.board.pieces.clear()
	s.board.invalidate_terrain()
	var source := Vector2i(12,71)
	var target := Vector2i(36,1)
	check_eq(BoardTopology.destinations(s.board,source),[target])
	check(BoardTopology.sources(s.board,target).has(source))
	var grid := MoveGrid.new(s.board)
	var r := MovePlanner.reach(grid,Vector2(6,35.5),2.0)
	check(r.can_reach(target))
	check(r.can_reach(target+Vector2i(0,2)))
	check_eq(r.cost.get(target),0.5)
	var saved := BattleSnapshot.capture(c)
	var restored := BattleSnapshot.rebuild(saved,s.creature_db)
	check(restored!=null)
	if restored!=null:
		check_eq(restored.state.board.edge_links,s.board.edge_links)
	check_eq(RedKingTethers.arrival(15),"")
	check_eq(RedKingTethers.arrival(20),"hrut_darter")
