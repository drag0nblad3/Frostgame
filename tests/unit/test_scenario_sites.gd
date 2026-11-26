extends TestCase


func test_haunted_hut_once_and_snapshot() -> void:
	var s := ScenarioLoader.load_id("haunted_houses", db(), terrain())
	var c := GameController.new(s, LoadedDice.new([17, 20]))
	var f := s.figure(1)
	f.pos = Vector2(18, 16.5)
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
	c._magic.treasure_magic.apply(s.figure(1), "telekinesis", s.treasure(1), Vector2(11, 17), 15)
	check_eq(s.discovered_huts.size(), 2)
	check_eq(s.figures.back().def.id, "ghoul")
	check_eq(s.treasure(1).pos, Vector2(11, 17))


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
	f.pos = Vector2(18, 8)
	f.actions_left = 2
	s.active_id = f.id
	s.forced_combat = false
	check(c.move_to(MovePlanner.node_at(Vector2(18, 11))))
	check_eq(s.discovered_huts.size(), 1)
	check_eq(f.pos, Vector2(18, 11))
