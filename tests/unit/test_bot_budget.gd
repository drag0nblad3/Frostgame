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
	var checks:=MoveGrid.evaluations+LayeredGrid.evaluations
	check(checks <= budget, "combined open checks %d over budget %d" % [checks,budget])
	check(avg <= AVG_MS_BUDGET, "average activation %.1f ms over %.0f ms" % [avg, AVG_MS_BUDGET])


## Exercise a separate multi-storey battlefield with the full activation
## lifecycle, including aerial previews, not just a synthetic path query.
func test_stacked_battle_work_profile() -> void:
	var c:=LayeredBattle.create(db(),terrain(),17)
	var s:=c.state
	MoveGrid.evaluations=0
	LayeredGrid.evaluations=0
	var before_edges:=LayeredGrid.edge_evaluations
	var samples: Array[float]=[]
	while not s.over and samples.size()<150:
		var start:=Time.get_ticks_usec()
		check(Bot.play_activation(c),"bot advances on stacked terrain")
		samples.append(float(Time.get_ticks_usec()-start)/1000.0)
	check(s.over,"stacked battle terminates")
	if samples.is_empty():
		return
	samples.sort()
	var total:=0.0
	for ms in samples:
		total+=ms
	var avg:=total/float(samples.size())
	var p95:=samples[mini(samples.size()-1,ceili(samples.size()*0.95)-1)]
	print("stacked bot budget: %d activations, %d layered open checks, %d edge calculations, %.1f ms mean, %.1f ms p95, %.1f ms max" % [samples.size(),LayeredGrid.evaluations,LayeredGrid.edge_evaluations-before_edges,avg,p95,samples[-1]])
	check(LayeredGrid.evaluations>0)
	# The stacked fixture has fewer figures and a smaller table but more
	# explicit floor connections; retain generous headroom for shared CI.
	check(avg<=AVG_MS_BUDGET,"stacked activation %.1f ms over %.0f ms" % [avg,AVG_MS_BUDGET])
