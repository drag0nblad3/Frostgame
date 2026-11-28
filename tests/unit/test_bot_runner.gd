extends TestCase
## Bot activations on a worker thread match inline play and buffer their events.


func _controller(seed_value: int) -> GameController:
	var s := ScenarioLoader.load_id("skirmish", db(), terrain())
	var c := GameController.new(s, Dice.new(seed_value))
	c.start_game()
	return c


func _play(c: GameController, threaded: bool, activations: int) -> Array[GameEvent]:
	var runner := BotRunner.new()
	runner.threaded = threaded
	var seen: Array[GameEvent] = []
	c.event_emitted.connect(func(e: GameEvent) -> void:
		if not runner.capture(e):
			seen.append(e))
	for i in activations:
		if c.state.over:
			break
		runner.start(c)
		while runner.busy() and not runner.done():
			OS.delay_usec(200)
		seen.append_array(runner.take_events())
	return seen


func test_threaded_matches_inline() -> void:
	var inline := _play(_controller(5), false, 12)
	var threaded := _play(_controller(5), true, 12)
	check(inline.size() > 0, "bot produced events")
	check_eq(threaded.size(), inline.size())
	for i in mini(inline.size(), threaded.size()):
		check_eq(threaded[i].type, inline[i].type)


func test_finish_drops_pending_events() -> void:
	var c := _controller(9)
	var runner := BotRunner.new()
	runner.threaded = true
	c.event_emitted.connect(func(e: GameEvent) -> void: runner.capture(e))
	runner.start(c)
	runner.finish()
	check(not runner.busy())
	check(runner.take_events().is_empty())


func test_finished_runner_releases_battle() -> void:
	for threaded in [false,true]:
		var c:=_controller(9)
		var runner:=BotRunner.new()
		runner.threaded=threaded
		var reference:=weakref(c)
		c.event_emitted.connect(func(e: GameEvent) -> void: runner.capture(e))
		runner.start(c)
		while runner.busy() and not runner.done():
			OS.delay_usec(200)
		check(runner._controller==null)
		c=null
		check(reference.get_ref()==null,"finished runner must not retain its battle")
		runner.finish()
