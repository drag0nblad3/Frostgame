extends TestCase


func test_column_won_by_moving_into_contact() -> void:
	var s := ScenarioLoader.load_id("complex_temple", db(), terrain())
	var c := GameController.new(s, LoadedDice.new([20, 1, 1]))
	var f := s.figure(1)
	f.pos = Vector2(15, 11)
	f.actions_left = 2
	s.active_id = f.id
	s.forced_combat = false
	check_eq(s.treasures.size(), 6)
	check(s.treasure(0).frozen)
	check(not c.can_pick_up(0))
	check(c.move_to(MovePlanner.node_at(Vector2(15, 14))))
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
	f.pos = Vector2(15, 14)
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
