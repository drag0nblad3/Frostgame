extends TestCase


func test_column_won_by_moving_into_contact() -> void:
	var s := ScenarioLoader.load_id("complex_temple", db(), terrain())
	var c := GameController.new(s, LoadedDice.new([20, 1, 1]))
	var f := s.figure(1)
	f.pos = Vector2(14, 12.5)
	f.actions_left = 2
	s.active_id = f.id
	s.forced_combat = false
	check_eq(s.treasures.size(), 6)
	check(s.treasure(0).frozen)
	check(not c.can_pick_up(0))
	check(c.move_on_floor(s.board.floor_geometry().node("street",Vector2(14,15))))
	check_eq(f.actions_left, 1)
	check_eq(f.moves_taken, 1)
	check_eq(f.treasure_id, 0)
	check_eq(s.treasure(0).carrier_id, f.id)
	check(not s.treasure(0).frozen)
	check(ScenarioColumns.contact(s.board, f.pos) == null)
	check(s.column_fighters.has(f.id))
	var restored := BattleSnapshot.rebuild(BattleSnapshot.capture(c), db())
	check(restored != null)
	check(not restored.state.treasure(0).frozen)
	check(restored.state.column_fighters.has(f.id))


func test_column_loss_and_retry() -> void:
	var s := ScenarioLoader.load_id("complex_temple", db(), terrain())
	var c := GameController.new(s, LoadedDice.new([1, 13, 20, 1, 1]))
	var f := s.figure(1)
	f.pos = Vector2(14, 15)
	f.actions_left = 2
	s.active_id = f.id
	var old := f.health
	check(ScenarioColumns.challenge(c, f))
	check(f.health < old)
	check(s.treasure(0).frozen)
	check(ScenarioColumns.challenge(c, f))
	check(not s.treasure(0).frozen)
	var xp := 0
	for e in c.history:
		if e.type == "column_fight":
			xp += int(e.data["xp"])
	check_eq(xp, 30)


func test_column_contact_is_symmetric() -> void:
	var s := ScenarioLoader.load_id("complex_temple", db(), terrain())
	for at: Vector2 in [Vector2(14, 15), Vector2(13, 16), Vector2(14, 17), Vector2(15, 16)]:
		check(s.board.can_stand(at, Figure.BASE_RADIUS), "legal edge contact")
		check(ScenarioColumns.contact(s.board, at) != null, "guardian triggers")
	check(not s.board.can_stand(Vector2(14, 15.25), Figure.BASE_RADIUS))
	check(not s.board.can_stand(Vector2(14, 16), Figure.BASE_RADIUS))


func test_revealed_treasure_may_be_left() -> void:
	var s:=ScenarioLoader.load_id("complex_temple",db(),terrain())
	var c:=GameController.new(s,LoadedDice.new([20,1]))
	s.reaction_side=0
	var f:=s.figure(1)
	f.pos=Vector2(14,15)
	check(ScenarioColumns.challenge(c,f))
	check_eq(CoreScenarioChoice.pending(c).get("kind",""),"column")
	check(BattleScenarioAction.execute(c,"core_choice",{"index":1}))
	check(s.treasure(0).on_ground())
	check(not s.treasure(0).frozen)
	check_eq(f.treasure_id,-1)
