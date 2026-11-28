extends TestCase


func test_haunted_hut_once_and_snapshot() -> void:
	var s := ScenarioLoader.load_id("haunted_houses", db(), terrain())
	var c := GameController.new(s, LoadedDice.new([17, 20]))
	var f := s.figure(1)
	f.pos = Vector2(18, 19.5)
	var before := s.figures.size()
	check(ScenarioSites.enter(c, f))
	check_eq(s.figures.size(), before + 1)
	check_eq(s.figures.back().def.id, "wraith")
	check_eq(c.history.back().data["xp"], 15)
	check(not ScenarioSites.enter(c, f))
	var restored := BattleSnapshot.rebuild(BattleSnapshot.capture(c), db())
	check(restored != null)
	check_eq(restored.state.discovered_huts.size(), 1)


func test_empty_hut_and_magic_discovery() -> void:
	var s := ScenarioLoader.load_id("haunted_houses", db(), terrain())
	var c := GameController.new(s, LoadedDice.new([6, 12]))
	check(not ScenarioSites.discover(c, Vector2(18, 18), 0))
	check_eq(s.discovered_huts.size(), 1)
	c._magic.treasure_magic.apply(s.figure(1), "telekinesis", s.treasure(1), Vector2(8, 17), 15)
	check_eq(s.discovered_huts.size(), 2)
	check_eq(s.figures.back().def.id, "ghoul")
	check_eq(s.treasure(1).pos, Vector2(8, 17))


func test_disc_transport_no_chain_and_once_xp() -> void:
	var s := ScenarioLoader.load_id("the_keep", db(), terrain())
	var c := GameController.new(s, LoadedDice.new([6, 6, 20]))
	var f := s.figure(1)
	f.pos = Vector2(18, 12)
	ScenarioSites.end_move(c, f)
	check_eq(f.pos, Vector2(18, 24))
	check_eq(c.history.back().data["xp"], 30)
	ScenarioSites.end_move(c, f)
	check_eq(f.pos, Vector2(18, 12))
	check_eq(c.history.back().data["xp"], 0)
	ScenarioSites.end_move(c, f)
	check_eq(f.pos, Vector2(18, 12))
	check(ScenarioSites.treasure_protected(s, s.treasure(1).pos))
	check(not ScenarioSites.treasure_protected(s, s.treasure(0).pos))
	check(not c._magic.treasure_magic.can_target(f, "telekinesis", s.treasure(1)))


func test_disc_hook_on_real_move_and_magic() -> void:
	var s := ScenarioLoader.load_id("the_keep", db(), terrain())
	var c := GameController.new(s, LoadedDice.new([6, 6]))
	var f := s.figure(1)
	f.pos = Vector2(18, 9)
	f.actions_left = 2
	s.active_id = f.id
	s.forced_combat = false
	check(c.move_to(MovePlanner.node_at(Vector2(18, 12))))
	check_eq(f.pos, Vector2(18, 24))
	check_eq(f.moves_taken, 1)
	check_eq(f.actions_left, 1)
	c._magic.movement.move(f, Vector2(24, 18))
	check_eq(f.pos, Vector2(12, 18))


func test_hut_discovered_on_real_movement() -> void:
	var s := ScenarioLoader.load_id("haunted_houses", db(), terrain())
	var c := GameController.new(s, LoadedDice.new([1]))
	var f := s.figure(1)
	f.pos = Vector2(20, 11)
	f.actions_left = 2
	s.active_id = f.id
	s.forced_combat = false
	check(c.move_to(MovePlanner.node_at(Vector2(20, 8))))
	check_eq(s.discovered_huts.size(), 1)
	check_eq(f.pos, Vector2(20, 8))


func test_hut_interrupts_stale_path_without_overlapping() -> void:
	var s := ScenarioLoader.load_id("haunted_houses", db(), terrain())
	var c := GameController.new(s, LoadedDice.new([12]))
	var f := s.figure(1)
	f.pos = Vector2(18, 8)
	# A valid path into the hut may become obstructed by its hidden occupant.
	var path := PackedVector2Array([Vector2(20, 11),Vector2(20,10.5),Vector2(20,10),Vector2(20,9.5),Vector2(20,9),Vector2(20,8.5),Vector2(20,8),Vector2(20,7.5),Vector2(20,7),Vector2(20,6.5)])
	c._magic.terrain.travel(f, path, 5.0)
	var occupant: Figure = s.figures.back()
	check_eq(occupant.def.id, "ghoul")
	check(f.pos.distance_to(occupant.pos) >= Contact.OVERLAP)
	check(Contact.in_combat(s.figures, f))


func test_haunted_hut_wall_spacing_and_entrances() -> void:
	var s:=ScenarioLoader.load_id("haunted_houses",db(),terrain())
	var c:=GameController.new(s,LoadedDice.new([12,12,12,12,12]))
	var huts: Array[TerrainPiece]=[]
	for p in s.board.pieces:
		if p.kind.id=="haunted_floor":
			huts.append(p)
	check_eq(huts.size(),5)
	check_eq(huts[0].rect.get_center(),s.board.size*0.5)
	var central:=huts[0].rect.grow(0.5)
	var directions: Dictionary={}
	for i in range(huts.size()):
		var hut:=huts[i]
		directions[hut.entrance]=true
		if i>0:
			var outer:=hut.rect.grow(0.5)
			var dx:=maxf(0.0,maxf(central.position.x-outer.end.x,outer.position.x-central.end.x))
			var dy:=maxf(0.0,maxf(central.position.y-outer.end.y,outer.position.y-central.end.y))
			check_eq(Vector2(dx,dy).length(),6.0)
		check_eq(s.treasures[i].pos,hut.rect.get_center())
		check(ScenarioSites.discover(c,hut.rect.get_center(),0))
		var occupant: Figure=s.figures.back()
		var target:=ScenarioSites.hut_spawn_target(hut)
		# A base touching the wall exactly can be rejected by the half-inch
		# standability lattice. The closest legal node may be one step inward.
		check(occupant.pos.distance_to(target)<=0.501)
		check(hut.rect.grow(-Figure.BASE_RADIUS+0.001).has_point(occupant.pos))
		check(s.board.can_stand(occupant.pos,Figure.BASE_RADIUS))
	check_eq(directions.size(),4)
	var restored:=BattleSnapshot.rebuild(BattleSnapshot.capture(c),db())
	for i in s.board.pieces.size():
		check_eq(restored.state.board.pieces[i].entrance,s.board.pieces[i].entrance)


func test_disc_destination_is_player_choice() -> void:
	var s:=ScenarioLoader.load_id("the_keep",db(),terrain())
	var c:=GameController.new(s,LoadedDice.new([6]))
	s.reaction_side=0
	var f:=s.figure(1)
	f.pos=Vector2(18,12)
	ScenarioSites.end_move(c,f)
	var d:=CoreScenarioChoice.pending(c)
	check_eq(d.get("kind",""),"disc")
	if d.is_empty():
		return
	check(d["options"].size()>1)
	var at: Vector2=d["options"][-1]["at"]
	check(BattleScenarioAction.execute(c,"core_choice",{"index":d["options"].size()-1}))
	check_eq(f.pos,at)
	check(not c.awaiting_reaction())
