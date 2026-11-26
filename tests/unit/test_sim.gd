extends TestCase
## Whole games, bot against bot, on the shipped scenario.


func _play(seed_value: int) -> GameController:
	var s := ScenarioLoader.load_id("skirmish", db(), terrain())
	var c := GameController.new(s, Dice.new(seed_value))
	c.start_game()
	var guard := 0
	while not s.over and guard < 1000:
		check(Bot.play_activation(c), "bot found an activation (seed %d)" % seed_value)
		guard += 1
	return c


func test_bot_games_finish() -> void:
	for seed_value in [3, 17, 42]:
		var c := _play(seed_value)
		check(c.state.over, "seed %d finished" % seed_value)
		var fights := 0
		for e in c.history:
			if e.type == "fight" or e.type == "shoot":
				fights += 1
		check(fights > 0, "seed %d had combat" % seed_value)


func test_no_overlapping_bases() -> void:
	var c := _play(7)
	var live := c.state.figures.filter(func(f: Figure) -> bool: return f.in_play())
	for i in live.size():
		for j in range(i + 1, live.size()):
			check(live[i].pos.distance_to(live[j].pos) >= Contact.OVERLAP - 0.01, "bases overlap")
