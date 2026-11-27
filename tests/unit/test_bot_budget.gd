extends TestCase
## Guards bot speed: a full bot-vs-bot game must stay within a fixed amount of
## movement-search work (deterministic) and a generous wall-clock budget.

## Measured at 89,127 (+25% headroom) when the open-square cache landed. Raise only on purpose.
const OPEN_BUDGET := 111400
const AVG_MS_BUDGET := 250.0


func test_bot_game_within_budget() -> void:
	var s := ScenarioLoader.load_id("skirmish", db(), terrain())
	var c := GameController.new(s, Dice.new(3))
	c.start_game()
	MoveGrid.evaluations = 0
	var started := Time.get_ticks_msec()
	var n := 0
	while not s.over and n < 1000:
		Bot.play_activation(c)
		n += 1
	var avg := float(Time.get_ticks_msec() - started) / maxf(1.0, n)
	print("bot budget: %d activations, %d open checks, %.1f ms average" % [n, MoveGrid.evaluations, avg])
	check(s.over, "game finished")
	check(MoveGrid.evaluations <= OPEN_BUDGET, "open checks %d over budget %d" % [MoveGrid.evaluations, OPEN_BUDGET])
	check(avg <= AVG_MS_BUDGET, "average activation %.1f ms over %.0f ms" % [avg, AVG_MS_BUDGET])
