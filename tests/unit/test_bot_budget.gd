extends TestCase
## Guards bot speed: a full bot-vs-bot game must stay within a fixed amount of
## movement-search work (deterministic) and a generous wall-clock budget.

## Measured at 89,127 (+25% headroom) when the open-square cache landed. Raise only on purpose.
const OPEN_BUDGET := 111400
# Corrected combat outcomes can add activations. Retain the original floor,
# enforce 1,114 checks per activation above 100 turns of work, and a hard ceiling.
const OPEN_PER_ACTIVATION := 1114
const OPEN_HARD_LIMIT := 200000
const AVG_MS_BUDGET := 250.0


func test_bot_game_within_budget() -> void:
	var s := ScenarioLoader.load_id("skirmish", db(), terrain())
	var c := GameController.new(s, Dice.new(3))
	c.start_game()
	MoveGrid.evaluations = 0
	LayeredGrid.evaluations=0
	var started := Time.get_ticks_msec()
	var n := 0
	while not s.over and n < 1000:
		Bot.play_activation(c)
		n += 1
	var avg := float(Time.get_ticks_msec() - started) / maxf(1.0, n)
	print("bot budget: %d activations, %d flat open checks, %d layered open checks, %.1f ms average" % [n, MoveGrid.evaluations,LayeredGrid.evaluations, avg])
	if not s.board.floor_layout.is_empty():
		check(LayeredGrid.evaluations>0,"shared grid evaluations measured")
	check(s.over, "game finished")
	var budget:=mini(OPEN_HARD_LIMIT,maxi(OPEN_BUDGET,n*OPEN_PER_ACTIVATION))
	check(MoveGrid.evaluations <= budget, "open checks %d over budget %d" % [MoveGrid.evaluations,budget])
	check(avg <= AVG_MS_BUDGET, "average activation %.1f ms over %.0f ms" % [avg, AVG_MS_BUDGET])
