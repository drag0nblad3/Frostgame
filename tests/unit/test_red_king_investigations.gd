extends TestCase


func _fixture() -> GameController:
	var packs := ContentProfile.registered().duplicate(true)
	packs["red_king"]["status"]="ready"
	var defs := FigureDb.load_files(FigureDb.FIGURES,FigureDb.WEAPONS,ContentProfile.new(["red_king"],packs))
	var s := ScenarioLoader.load_id("red_king_investigations",defs,terrain())
	var c := GameController.new(s,Dice.new(38))
	RedKingInvestigations.prepare(c)
	return c


func test_stands_are_not_treasure_until_investigated() -> void:
	var c := _fixture()
	var s := c.state
	check_eq(s.treasures.size(),7)
	var token := s.treasures[0]
	check(token.investigation)
	var f := s.figures[0]
	f.pos=token.pos+Vector2(0.5,0)
	f.actions_left=2
	s.active_id=f.id
	for other in s.figures:
		if other!=f:
			other.pos=Vector2(2,2)
	check(not TreasureRules.can_pick_up(s,f,token))
	check(not c._magic.treasure_magic.can_target(f,"telekinesis",token))
	s.scenario_data["stand_deck"]={"remaining":["gold100"],"discard":[]}
	check(c.pick_up(token.id))
	check(not token.investigation)
	check_eq(token.bonus_gold,100)
	check_eq(f.treasure_id,token.id)
	check_eq(f.actions_left,1)
	check_eq(s.scenario_data["stand_deck"]["remaining"].size(),0)


func test_alarm_escape_and_reinforcement_limit() -> void:
	var c := _fixture()
	var s := c.state
	check(not s.scenario_data["alarm"])
	c.emit("cast_result",{"spell":"elemental_bolt","success":true})
	check(s.scenario_data["alarm"])
	var before := s.figures.size()
	for turn in range(1,10):
		s.turn=turn
		RedKingInvestigations.end_turn(c)
	check_eq(s.scenario_data["reinforcements"],6)
	check_eq(s.figures.size(),before+6)
	check(not RedKingInvestigations.exit_allowed(s,Vector2(18,0.5),0))
	check(RedKingInvestigations.exit_allowed(s,Vector2(18,35.5),0))
	check(RedKingInvestigations.exit_allowed(s,Vector2(18,0.5),1))
	check(not RedKingInvestigations.exit_allowed(s,Vector2(18,35.5),1))
	var snapshot := BattleSnapshot.capture(c)
	check(not snapshot.is_empty())
	var rebuilt := BattleSnapshot.rebuild(snapshot,s.creature_db)
	check(rebuilt!=null)
	if rebuilt!=null:
		check_eq(rebuilt.state.scenario_data,s.scenario_data)
		check(rebuilt.state.treasures[0].investigation)
