extends TestCase


func test_well_drink_once() -> void:
	var s := ScenarioLoader.load_id("dreams_well", db(), terrain())
	var c := GameController.new(s, Dice.new(2))
	var f := s.figure(1)
	f.pos = Vector2(18, 16)
	f.actions_left = 2
	s.active_id = f.id
	check(c.can_drink_well())
	check(c.drink_well())
	check(not c.drink_well())
	check_eq(c.history.back().data["xp"], 50)
	check(not s.treasure(0).central)


func test_worm_only_spawns_once() -> void:
	var s := ScenarioLoader.load_id("worm_hunts", db(), terrain())
	var c := GameController.new(s, LoadedDice.new([20, 20]))
	for token in s.treasures:
		token.pos = Vector2(18, 12)
	ScenarioObjectives.spawn_worm(c)
	check(s.worm_spawned)
	var size := s.figures.size()
	ScenarioObjectives.spawn_worm(c)
	check_eq(s.figures.size(), size)
	check_eq(s.figures.back().def.id, "giant_worm")
	check_eq(s.figures.back().def.health, 20)
