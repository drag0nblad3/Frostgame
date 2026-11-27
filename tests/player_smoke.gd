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
		var actions := c.state.active().actions_left
		var moves := c.state.active().moves_taken
		var rng := c.dice._rng.state
		var history := c.history.size()
		var destinations: Array[Vector2i]=[]
		for n: Vector2i in _scene.player_input.nodes:
			var at := MoveGrid.to_pos(n)
			if start.distance_to(at) >= 1.0:
				destinations.append(n)
			if destinations.size()>=2:
				break
		if destinations.size()<2:
			return _fail("No useful movement preview")
		for n in destinations:
			var at := MoveGrid.to_pos(n)
			var p: Vector2=_scene._rig.camera.unproject_position(TableSpace.to_world(at))
			if _scene.player_input.tap(p) or _scene.player_input.move_destination!=n:
				return _fail("Movement tap did not create a reversible draft")
			if c.state.active().pos!=start or c.state.active().actions_left!=actions or c.state.active().moves_taken!=moves or c.dice._rng.state!=rng or c.history.size()!=history:
				return _fail("Movement draft changed rules state or consumed RNG")
		_scene.player_input.action("move_reset")
		if _scene.player_input.move_destination!=null or c.state.active().pos!=start or _scene.player.views[c.state.active().id].position!=TableSpace.to_world(start,c.state.active().elevation):
			return _fail("Reset did not restore movement origin")
		_scene.player_input.plan_move(destinations[0])
		if not _scene.player_input.action("move_confirm"):
			return _fail("Confirm move failed")
		_stage=2
		return false
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
