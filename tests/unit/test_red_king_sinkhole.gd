extends TestCase


func _fixture() -> GameController:
	var packs := ContentProfile.registered().duplicate(true)
	packs["red_king"]["status"]="ready"
	var defs := FigureDb.load_files(FigureDb.FIGURES,FigureDb.WEAPONS,ContentProfile.new(["red_king"],packs))
	return GameController.new(ScenarioLoader.load_id("red_king_sinkhole",defs,terrain()),Dice.new(38))


func test_orb_geometry_casting_and_contact() -> void:
	var c := _fixture()
	var s := c.state
	check_eq(s.treasures.size(),6)
	check_eq(s.side_figures(-1).size(),6)
	check(not s.board.can_stand(Vector2(18,18),Figure.BASE_RADIUS))
	check(s.board.can_stand(Vector2(20,18),Figure.BASE_RADIUS))
	check(not LineOfSight.check(s.board,Vector2(15,18),Vector2(21,18)).clear)
	var f := s.figures[0]
	f.pos=Vector2(18,5)
	check_eq(RedKingSinkhole.casting_modifier(s,f),-1)
	f.pos=Vector2(18,11)
	check_eq(RedKingSinkhole.casting_modifier(s,f),-2)
	f.pos=Vector2(18,16)
	check_eq(RedKingSinkhole.casting_modifier(s,f),-4)
	f.spell_effects["strength"]=true
	var hp := f.health
	RedKingSinkhole.activation(c,f)
	check_eq(f.health,hp-6)
	check(not f.spell_effects.has("strength"))


func test_gravity_nullman_immunity_and_checkpoint() -> void:
	var c := _fixture()
	var s := c.state
	var f := s.figures[0]
	f.pos=Vector2(18,12)
	var token := s.treasures[0]
	token.pos=Vector2(18,20)
	var nullman: Figure=s.side_figures(-1)[0]
	var original := nullman.pos
	RedKingSinkhole.pull(c,f)
	check_eq(f.pos,Vector2(18,13))
	RedKingSinkhole.pull(c,nullman)
	check_eq(nullman.pos,original)
	RedKingSinkhole.end_turn(c)
	check(token.lost)
	check(s.scenario_data.get("sinkhole_xp_flags",{}).has("%d:near_orb"%f.id))
	var saved := BattleSnapshot.capture(c)
	var restored := BattleSnapshot.rebuild(saved,s.creature_db)
	check(restored!=null)
	if restored!=null:
		check_eq(restored.state.scenario_data,s.scenario_data)
		check(restored.state.treasures[0].lost)
