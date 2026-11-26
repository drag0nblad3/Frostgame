extends TestCase


func _fixture() -> GameController:
	var packs := ContentProfile.registered().duplicate(true)
	packs["red_king"]["status"]="ready"
	var defs := FigureDb.load_files(FigureDb.FIGURES,FigureDb.WEAPONS,ContentProfile.new(["red_king"],packs))
	var s := ScenarioLoader.load_id("red_king_demons_and_mad_man",defs,terrain())
	return GameController.new(s,Dice.new(38))


func test_rescue_is_not_normal_damage_or_loot() -> void:
	var c := _fixture()
	var s := c.state
	var npc := s.figure(int(s.scenario_data["ryce_id"]))
	var rescue := s.treasure(int(s.scenario_data["ryce_token"]))
	check_eq(npc.def.armour,18)
	check(rescue.lost)
	c._hurt(npc,99,s.figures[0])
	check(npc.in_play())
	RedKingMadMan.knock_out(c,npc,s.figures[0])
	check(not npc.in_play())
	check(rescue.on_ground())
	check_eq(rescue.pos,npc.pos)
	check(RedKingMadMan.rescue(s,rescue))
	var snapshot := BattleSnapshot.capture(c)
	var restored := BattleSnapshot.rebuild(snapshot,s.creature_db)
	check(restored!=null)
	if restored!=null:
		check(restored.state.treasure(rescue.id).on_ground())


func test_hunting_parties_and_edge_exchange() -> void:
	var c := _fixture()
	var s := c.state
	s.scenario_data["reduced_hunters_0"]=true
	RedKingMadMan.deploy_hunters(c)
	var counts := [0,0]
	for f in s.figures:
		if RedKingMadMan.hunter(f):
			counts[f.side]+=1
	check_eq(counts,[2,3])
	var wizard := s.figures[0]
	wizard.pos=Vector2(18,2)
	var old := wizard.pos
	RedKingMadMan.reality_crack(c,true)
	check(wizard.pos.y>old.y+20.0)
