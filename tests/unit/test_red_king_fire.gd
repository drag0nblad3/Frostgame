extends TestCase


func _fixture() -> GameController:
	var packs := ContentProfile.registered().duplicate(true)
	packs["red_king"]["status"]="ready"
	var defs := FigureDb.load_files(FigureDb.FIGURES,FigureDb.WEAPONS,ContentProfile.new(["red_king"],packs))
	var s := ScenarioLoader.load_id("red_king_back_into_fire",defs,terrain())
	return GameController.new(s,Dice.new(38))


func test_stealth_locked_treasure_and_exit_zones() -> void:
	var c := _fixture()
	var s := c.state
	check_eq(s.treasures.size(),5)
	check(RedKingFire.locked(s,s.treasures[0]))
	check_eq(RedKingFire.portals(s).size(),3)
	for f in s.figures:
		if f.side>=0:
			check(f.spell_effects.has("invisibility"))
			check(f.pos.y<6.0)
	check(RedKingFire.exit_allowed(s,Vector2(0.5,2)))
	check(not RedKingFire.exit_allowed(s,Vector2(0.5,18)))
	var wizard := s.figures[0]
	check_eq(RedKingFire.unlock_bonus(wizard),5)
	check(not c._magic.treasure_magic.can_target(wizard,"telekinesis",s.treasures[0]))
	check(not LineOfSight.check(s.board,Vector2(18,22),Vector2(18,26)).clear)


func test_portal_contact_and_arrival_schedule() -> void:
	var c := _fixture()
	var s := c.state
	var f := s.figures[0]
	var gate := RedKingFire.portals(s)[0]
	var center := gate.rect.get_center()
	var hp := f.health
	var hits := {}
	RedKingFire.portal_contact(c,f,center+Vector2(2,0),center+Vector2(1.5,0),hits)
	check_eq(f.health,hp-5)
	RedKingFire.portal_contact(c,f,center+Vector2(2,0),center+Vector2(1.5,0),hits)
	check_eq(f.health,hp-5)
	var before := s.figures.size()
	for turn in range(1,10):
		s.turn=turn
		RedKingFire.end_turn(c)
	check_eq(s.figures.size(),before+7)
	var save := BattleSnapshot.capture(c)
	check(not save.is_empty())
	var restored := BattleSnapshot.rebuild(save,s.creature_db)
	check(restored!=null)
	if restored!=null:
		check(RedKingFire.locked(restored.state,restored.state.treasures[0]))
		check_eq(RedKingFire.portals(restored.state).size(),3)
