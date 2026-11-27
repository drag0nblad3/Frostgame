extends SceneTree
## Same scene and same BattleInput contract as ordinary player_smoke.

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.set_meta("layered_board","stacked_gatehouse")
	change_scene_to_file("res://scenes/main.tscn")
	await scene_changed
	var scene: BattleScene=current_scene
	scene._bots.threaded=false
	scene.player.speed=50.0
	var c:=scene.controller
	var layout:=FloorLayout.from_dict(c.state.board.floor_layout)
	if c.state.figures.size()!=6 or not layout.errors.is_empty() or not scene.hud._floor_choice.visible or scene._board_view._floor_art==null:
		_fail("Layered board failed to attach to common battle")
		return
	for i in 6:
		if c.state.current_side()==0:
			break
		Bot.play_activation(c)
		scene.player._queue.clear()
	if c.state.current_side()!=0 or c.activatable().is_empty():
		_fail("No human activation")
		return
	scene.player._queue.clear()
	scene._refresh()
	var f:=c.activatable()[0]
	var v: FigureView=scene.player.views[f.id]
	scene._select_floor(f.surface_id)
	var screen:=scene._rig.camera.unproject_position(v.position+Vector3.UP*0.75)
	if not scene.player_input.tap(screen):
		_fail("Cannot activate via shared input")
		return
	scene.player._queue.clear()
	scene._refresh()
	var bi:=scene.player_input
	bi.action("move")
	if bi.movement==null or bi.movement.cost.is_empty():
		_fail("No floor-specific movement options")
		return
	var node: Vector3i=bi.movement.cost.keys()[0]
	var start:=f.pos
	var surface:=f.surface_id
	var actions:=f.actions_left
	var rng:=c.dice._rng.state
	var history:=c.history.size()
	bi.move_plan.choose_node(bi,node)
	if f.pos!=start or f.surface_id!=surface or f.actions_left!=actions or f.moves_taken!=0 or c.dice._rng.state!=rng or c.history.size()!=history:
		_fail("Shared floor preview mutated state")
		return
	scene._select_floor(layout.surface_id(node))
	if bi.move_plan.destination!=node:
		_fail("Floor selection discarded a movement draft")
		return
	bi.action("move_undo")
	if bi.move_plan.destination!=null or v.position!=TableSpace.to_world(start,f.elevation):
		_fail("Shared floor undo failed")
		return
	bi.action("move")
	bi.move_plan.choose_node(bi,node)
	if not bi.action("move_confirm") or f.moves_taken!=1 or f.actions_left!=actions-1:
		_fail("Shared floor movement command failed")
		return
	print("Layered skirmish smoke passed using standard scene, HUD and movement plan")
	quit(0)


func _fail(message: String) -> void:
	printerr(message)
	quit(1)
