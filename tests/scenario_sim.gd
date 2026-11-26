extends SceneTree
## Full seeded bot-v-bot scenario run, separate from the quick unit suite.
## godot --headless -s tests/scenario_sim.gd -- silent_tower 17

var errors: Array[String] = []


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var id := args[0] if args.size() > 0 else "treasure_skirmish"
	var seed_value := int(args[1]) if args.size() > 1 else 17
	var db := FigureDb.load_files()
	var terrain := TerrainDb.load_file()
	var s := ScenarioLoader.load_id(id, db, terrain)
	var c := GameController.new(s, Dice.new(seed_value))
	_validate(s, "deployment")
	c.start_game()
	var activations := 0
	var start := Time.get_ticks_msec()
	while not s.over and activations < 2000:
		if not Bot.play_activation(c):
			errors.append("No legal bot activation at turn %d phase %s" % [s.turn, str(s.phase)])
			break
		activations += 1
		_validate(s, "activation %d" % activations)
		if not errors.is_empty():
			break
	if not s.over:
		errors.append("Game failed to finish within activation guard")
	var counts := {}
	for e in c.history:
		counts[e.type] = int(counts.get(e.type, 0)) + 1
	var scores: Array[int] = []
	for side in s.side_count():
		scores.append(s.secured_count(side))
	print("SCENARIO_RESULT|", JSON.stringify({"id": id, "seed": seed_value, "turn": s.turn, "activations": activations, "winner": s.winner, "scores": scores, "events": counts, "elapsed_ms": Time.get_ticks_msec() - start, "errors": errors}))
	for msg in errors:
		printerr("FAIL ", msg)
	quit(0 if errors.is_empty() else 1)


func _validate(s: GameState, where: String) -> void:
	var live: Array[Figure] = []
	for f in s.figures:
		if not f.in_play():
			continue
		live.append(f)
		if not s.board.can_stand(f.pos, Figure.BASE_RADIUS):
			errors.append("%s: figure %d stands in illegal terrain at %s" % [where, f.id, str(f.pos)])
		if not is_equal_approx(f.elevation, s.board.height_at(f.pos)):
			errors.append("%s: figure %d has stale elevation" % [where, f.id])
	for i in live.size():
		for j in range(i + 1, live.size()):
			var a := live[i]
			var b := live[j]
			if absf(a.elevation - b.elevation) < 0.5 and a.pos.distance_to(b.pos) < Contact.OVERLAP - 0.01:
				errors.append("%s: figures %d and %d overlap" % [where, a.id, b.id])
	for t in s.treasures:
		if t.carrier_id < 0:
			continue
		var f := s.figure(t.carrier_id)
		if f == null or not f.in_play() or not f.carried_treasures().has(t.id):
			errors.append("%s: treasure %d has invalid carrier" % [where, t.id])
	for f in live:
		for id in f.carried_treasures():
			var t := s.treasure(id)
			if t == null or t.carrier_id != f.id:
				errors.append("%s: figure %d carries inconsistent treasure %d" % [where, f.id, id])
