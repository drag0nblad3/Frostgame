extends TestCase


func _board() -> Board:
	return BoardLoader.from_dict({"size":[36,36],"floor_layout":{"surfaces":[{"id":"street","rect":[0,0,36,36],"level":0},{"id":"roof","rect":[2,2,32,32],"level":4}],"solids":[[2,3.8,2,32,0.2,32]]},"pieces":[{"kind":"red_king_portal","rect":[17,17,2,2]}]},terrain())


func test_locked_artefact_and_stand_require_actual_support() -> void:
	var b:=_board()
	var f:=fig("wizard",0,Vector2(6,6))
	f.surface_id="roof"
	f.elevation=4.0
	var c:=make_game(b,[f],LoadedDice.new([20]))
	c.state.active_id=f.id
	f.actions_left=2
	var token:=TreasureToken.new(0,Vector2(6.5,6))
	token.central=true
	token.frozen=true
	token.surface_id="street"
	c.state.treasures.append(token)
	c.state.scenario_special=RedKingFire.ID
	check(not RedKingFire.can_unlock(c,token))
	token.surface_id="roof"
	check(RedKingFire.can_unlock(c,token))
	c.state.scenario_special=RedKingInvestigations.ID
	token.investigation=true
	token.surface_id="street"
	check(not RedKingInvestigations.can_investigate(c,token))
	token.surface_id="roof"
	check(RedKingInvestigations.can_investigate(c,token))


func test_portal_contact_does_not_harm_upper_floor() -> void:
	var b:=_board()
	var f:=fig("wizard",0,Vector2(15,18))
	f.surface_id="roof"
	f.elevation=4.0
	var c:=make_game(b,[f],LoadedDice.new([20]))
	c.state.scenario_special=RedKingFire.ID
	var hp:=f.health
	var seen: Dictionary={}
	RedKingFire.portal_contact(c,f,Vector2(16,18),Vector2(16.5,18),seen,4.0,4.0)
	check_eq(f.health,hp)
	RedKingFire.portal_contact(c,f,Vector2(16,18),Vector2(16.5,18),seen,0.0,0.0)
	check_eq(f.health,hp-5)
	RedKingFire.portal_contact(c,f,Vector2(16,18),Vector2(16.5,18),seen,0.0,0.0)
	check_eq(f.health,hp-5)


func test_room_threshold_only_on_ground_level() -> void:
	var b:=_board()
	var f:=fig("wizard",0,Vector2(15,18))
	f.surface_id="roof"
	f.elevation=4.0
	var c:=make_game(b,[f],LoadedDice.new([1]))
	c.state.scenario_special=RedKingSquatter.ID
	c.state.active_id=f.id
	f.actions_left=2
	check(RedKingSquatter.permit_step(c,f,Vector2(16,18),4.0))
	check(not c.state.scenario_data.has("squatter_passed"))
	check(not RedKingSquatter.permit_step(c,f,Vector2(16,18),0.0))
	check_eq(f.actions_left,0)


func test_ground_spawn_cannot_select_roof() -> void:
	var b:=_board()
	var c:=make_game(b,[],LoadedDice.new([20]))
	var n: Variant=BattlePlacement.nearest_ground(c.state,Vector2(8,8),2.0)
	check(n!=null)
	if n!=null:
		check_eq(b.floor_geometry().surface_id(n),"street")
	b.floor_layout["spawn_surfaces"]=["missing"]
	check(BattlePlacement.nearest_ground(c.state,Vector2(8,8),2.0)==null)


func test_first_expansion_maps_adopt_shared_floor_graph() -> void:
	var profile:=ContentProfile.new(["red_king"])
	var defs:=FigureDb.load_files(FigureDb.FIGURES,FigureDb.WEAPONS,profile)
	for id: String in ["red_king_investigations","red_king_squatter","red_king_demons_and_mad_man","red_king_veil","red_king_herded","red_king_mind","red_king_hill","red_king_back_into_fire","red_king_sinkhole","red_king_tethers","red_king_bridge","red_king_ringworld"]:
		var s:=ScenarioLoader.load_id(id,defs,terrain())
		check(not s.board.floor_layout.is_empty(),id)
		var l:=s.board.floor_geometry()
		check(l.errors.is_empty(),id+":"+str(l.errors))
		check(not s.scenario_data.has("support_errors"),id+":"+str(s.scenario_data.get("support_errors",[])))
		for f in s.figures:
			var n:=l.node(f.surface_id,f.pos)
			check(l.standable(n),id+" figure "+str(f.id))
			check_eq(l.point(n),f.pos)
			check_eq(l.height(n),f.elevation)
		for t in s.treasures:
			if t.on_ground():
				check_eq(t.surface_id,"street")
				check(not is_nan(TreasureRules.token_height(s,t)))
		check(l.index_of("street")>=0,id+" ground support")


func test_round_obstacle_clearance_and_sight() -> void:
	var b:=BoardLoader.from_dict({"size":[36,36],"shared_climbing":true,"pieces":[{"kind":"red_king_sinkhole_orb","rect":[16.5,16.5,3,3]}]},terrain())
	var l:=b.floor_geometry()
	check_eq(l.circular_solids.size(),1)
	check(not l.standable(l.node("street",Vector2(18,18))))
	check(l.standable(l.node("street",Vector2(19.5,19.5))))
	check(l.standable(l.node("street",Vector2(20,18))))
	check(not LayeredSight.clear(l,Vector3(15,1,18),Vector3(21,1,18)))
	check(LayeredSight.clear(l,Vector3(15,4,18),Vector3(21,4,18)))
	check(LayeredSight.clear(l,Vector3(19.4,1,19.4),Vector3(21,1,21)))


func test_bridge_and_ringworld_shared_routes() -> void:
	var profile:=ContentProfile.new(["red_king"])
	var defs:=FigureDb.load_files(FigureDb.FIGURES,FigureDb.WEAPONS,profile)
	var s:=ScenarioLoader.load_id("red_king_bridge",defs,terrain())
	var c:=GameController.new(s,Dice.new(17))
	var f:=s.figures[0]
	var l:=s.board.floor_geometry()
	var g:=LayeredGrid.new(l,f,s.figures)
	check(not g.open(l.node("street",Vector2(5,33))))
	check(g.open(l.node("street",Vector2(15,35))))
	s=ScenarioLoader.load_id("red_king_ringworld",defs,terrain())
	l=s.board.floor_geometry()
	check(BoardTopology.floor_destinations(s.board,l,l.node("street",Vector2(10,0.5))).has(l.node("street",Vector2(10,35.5))))
