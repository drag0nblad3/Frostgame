extends SceneTree
## Exercise player-facing commands against the actual battle scene.

var _scene: Node
var _started := 0
var _frames := 0
var _stage := 0


func _initialize() -> void:
	_scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(_scene)
	_started = Time.get_ticks_msec()


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 1:
		if not _scene.has_method("new_game"):
			return _fail("Battle scene script did not load")
		_scene.new_game(1)
		_scene.player.speed = 30.0
		return false
	if Time.get_ticks_msec() - _started > 30000:
		printerr("Player smoke timed out")
		quit(1)
		return true
	if not _scene.player.idle() or _scene._dirty:
		return false
	var c: GameController = _scene.controller
	if c.state.current_side() != 0:
		return false
	if _stage == 0:
		var options := c.activatable()
		if options.is_empty():
			return _fail("No selectable player figure")
		var p: Vector2 = _scene._rig.camera.unproject_position(TableSpace.to_world(options[0].pos, 0.75))
		if not _scene.player_input.tap(p) or c.state.active() == null:
			return _fail("Player selection failed")
		_stage = 1
	elif _stage == 1:
		if not _scene.player_input.available.has("move"):
			return _fail("Move not available")
		_scene.player_input.action("move")
		var start := c.state.active().pos
		for n: Vector2i in _scene.player_input.nodes:
			var at := MoveGrid.to_pos(n)
			if start.distance_to(at) < 1.0:
				continue
			var p: Vector2 = _scene._rig.camera.unproject_position(TableSpace.to_world(at))
			var before_actions := c.state.active().actions_left
			var before_moves := c.state.active().moves_taken
			var before_rng := c.dice._rng.state
			var before_history := c.history.size()
			var bi: BattleInput=_scene.player_input
			bi.tap(p)
			if bi.move_plan.destination==null or c.state.active().pos!=start or c.state.active().actions_left!=before_actions:
				return _fail("Tentative move mutated game state")
			if not bi.available.has("move_confirm") or not bi.available.has("move_undo"):
				return _fail("Movement confirmation missing")
			bi.action("move_undo")
			if bi.move_plan.destination!=null or c.state.active().pos!=start or c.state.active().moves_taken!=before_moves or c.dice._rng.state!=before_rng or c.history.size()!=before_history:
				return _fail("Undo changed state or revealed a roll")
			bi.tap(p)
			# Retarget while preserving the original allowance.
			for next: Vector2i in bi.nodes:
				if next!=n and start.distance_to(MoveGrid.to_pos(next))>=1.0:
					bi.move_plan.choose(bi,MoveGrid.to_pos(next))
					break
			if c.state.active().pos!=start or c.state.active().actions_left!=before_actions or c.dice._rng.state!=before_rng:
				return _fail("Retarget spent movement")
			if not bi.action("move_confirm"):
				return _fail("Legal movement confirmation failed")
			_stage = 2
			return false
		return _fail("No useful movement preview")
	elif _stage == 2:
		if not _scene.player_input.action("end") or c.state.active() != null:
			return _fail("End activation failed")
		print("Player smoke passed: select, preview, move, end")
		quit(0)
		return true
	return false


func _fail(message: String) -> bool:
	printerr(message)
	quit(1)
	return true
