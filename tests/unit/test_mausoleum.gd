extends TestCase


func test_mausoleum_setup_and_spawn() -> void:
	var s := ScenarioLoader.load_id("mausoleum", db(), terrain())
	check_eq(s.treasures.size(), 6)
	check_eq(s.side_figures(-1).size(), 6)
	check_eq(s.reinforcement_points.size(), 4)
	var c := GameController.new(s, Dice.new(1))
	c._encounters.on_end_turn()
	check_eq(s.side_figures(-1).size(), 7)
