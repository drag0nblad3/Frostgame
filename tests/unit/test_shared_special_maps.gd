extends TestCase

func test_new_special_maps_keep_exact_objectives_and_legal_support() -> void:
	for id in ["dreams_well","complex_temple","living_museum"]:
		var s:=ScenarioLoader.load_id(id,db(),terrain())
		var l:=s.board.floor_geometry()
		check(l.errors.is_empty(),id+":"+str(l.errors))
		check(not s.scenario_data.has("support_errors"),id+":"+str(s.scenario_data.get("support_errors",[])))
		check(not s.board.floor_layout.is_empty(),id)
		var data: Dictionary=JsonFile.read(ScenarioLoader.DIR+id+".json")
		for i in s.treasures.size():
			var t:=s.treasures[i]
			var at: Array=data["treasures"][i]
			check_eq(t.pos,Vector2(at[0],at[1]))
			check_eq(t.surface_id,"street")
			check(not is_nan(TreasureRules.token_height(s,t)))
			if id=="complex_temple":
				check(t.frozen)

func test_defeated_guardian_removes_collision_and_keeps_treasure_support() -> void:
	var s:=ScenarioLoader.load_id("complex_temple",db(),terrain())
	var c:=GameController.new(s,LoadedDice.new([20,1]))
	var f:=s.figure(1)
	f.pos=Vector2(14,15)
	s.reaction_side=0
	var l:=s.board.floor_geometry()
	var n:=l.node("street",Vector2(14,16))
	check(not l.standable(n))
	check(ScenarioColumns.challenge(c,f))
	check(BattleScenarioAction.execute(c,"core_choice",{"index":1}))
	l=s.board.floor_geometry()
	check(l.standable(l.node("street",Vector2(14,16))))
	check_eq(s.treasure(0).surface_id,"street")
	check(s.treasure(0).on_ground())
	check(not s.treasure(0).frozen)

func test_museum_statue_replaced_by_construct_on_real_support() -> void:
	var s:=ScenarioLoader.load_id("living_museum",db(),terrain())
	var c:=GameController.new(s,LoadedDice.new([20,0]))
	var f:=s.figure(1)
	check(c._encounters.museum_pickup(f))
	var creatures:=s.side_figures(-1)
	check_eq(creatures.size(),1)
	if creatures.size()!=1:
		return
	var construct:=creatures[0]
	check_eq(construct.surface_id,"street")
	var l:=s.board.floor_geometry()
	check(l.standable(l.node(construct.surface_id,construct.pos)))
	check_eq(construct.elevation,0.0)
	for p in s.board.pieces:
		if p.kind.id=="museum_statue":
			check(p.rect.get_center().distance_to(construct.pos)>1.0)


func test_mausoleum_corner_tokens_and_reinforcements_use_street() -> void:
	var s:=ScenarioLoader.load_id("mausoleum",db(),terrain())
	check(not s.scenario_data.has("support_errors"),str(s.scenario_data.get("support_errors",[])))
	var l:=s.board.floor_geometry()
	check(l.errors.is_empty(),str(l.errors))
	for t in s.treasures:
		check(not t.central)
		check_eq(t.surface_id,"street")
		check_eq(TreasureRules.token_height(s,t),0.0)
	for f in s.figures:
		check(l.standable(l.node(f.surface_id,f.pos)))
	var c:=GameController.new(s,LoadedDice.new([1]))
	var count:=s.figures.size()
	c._encounters.on_end_turn()
	check_eq(s.figures.size(),count+1)
	if s.figures.size()>count:
		check_eq(s.figures[-1].surface_id,"street")

func test_remaining_named_scenarios_have_shared_geometry() -> void:
	for id in ["haunted_houses","the_keep","mausoleum"]:
		var s:=ScenarioLoader.load_id(id,db(),terrain())
		check(not s.board.floor_layout.is_empty(),id)
		check(s.board.floor_geometry().errors.is_empty(),id)
		check(not s.scenario_data.has("support_errors"),id+":"+str(s.scenario_data.get("support_errors",[])))
		for t in s.treasures:
			check_eq(t.surface_id,"street")
