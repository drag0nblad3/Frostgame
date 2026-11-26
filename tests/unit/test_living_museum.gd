extends TestCase


func test_statues_and_pickup() -> void:
	var s := ScenarioLoader.load_id("living_museum", db(), terrain())
	check_eq(s.treasures.size(), 5)
	check_eq(s.side_figures(-1).size(), 0)
	var c := GameController.new(s, LoadedDice.new([1, 20]))
	var f := s.figure(1)
	check(not c._encounters.museum_pickup(f))
	check_eq(s.side_figures(-1).size(), 0)
	check(c._encounters.museum_pickup(f))
	check_eq(s.side_figures(-1).size(), 1)
	check_eq(s.side_figures(-1)[0].def.id, "medium_construct")
	var count := 0
	for p in s.board.pieces:
		if p.kind.id == "museum_statue":
			count += 1
	check_eq(count, 4)
