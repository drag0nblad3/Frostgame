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



func test_library_ice_and_doorways() -> void:
	var s := ScenarioLoader.load_id("underground_library", db(), terrain())
	var c := GameController.new(s, LoadedDice.new([1, 20]))
	var f := s.figure(1)
	f.pos = Vector2(18, 17.5)
	f.actions_left = 2
	s.active_id = f.id
	check(s.treasure(0).frozen)
	check(not c.can_pick_up(0))
	check(c.break_ice())
	check(s.treasure(0).frozen)
	f.acted = false
	f.actions_left = 2
	check(c.break_ice())
	check(not s.treasure(0).frozen)
	check(ScenarioObjectives.exit_allowed(s, Vector2(18, 0.5)))
	check(not ScenarioObjectives.exit_allowed(s, Vector2(8, 0.5)))
	check_eq(ScenarioObjectives.library_roll(1, LoadedDice.new([17])), 17)
	check_eq(ScenarioObjectives.library_roll(6, LoadedDice.new([17])), 6)


func test_primary_player_selects_worm_position() -> void:
	var s:=ScenarioLoader.load_id("worm_hunts",db(),terrain())
	var c:=GameController.new(s,LoadedDice.new([20]))
	s.reaction_side=0
	s.order.assign([0,1])
	for t in s.treasures:
		t.pos=Vector2(18,12)
	ScenarioObjectives.spawn_worm(c)
	var d:=CoreScenarioChoice.pending(c)
	check_eq(d.get("kind",""),"worm")
	if d.is_empty():
		return
	var at: Vector2=d["options"][0]["at"]
	check(BattleScenarioAction.execute(c,"core_choice",{"index":0}))
	check(s.worm_spawned)
	check_eq(s.figures.back().pos,at)
