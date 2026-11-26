extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	change_scene_to_file("res://scenes/layered_skirmish.tscn")
	await scene_changed
	var scene := current_scene
	var c: GameController = scene.controller
	if c.state.figures.size()!=6 or not scene.layout.errors.is_empty():
		printerr("Invalid layered skirmish")
		quit(1)
		return
	# Advance the rival if it won initiative, until the human can activate.
	for i in range(6):
		if c.state.current_side()==0:
			break
		Bot.play_activation(c)
		scene.player._queue.clear()
	if c.state.current_side()!=0 or c.activatable().is_empty():
		printerr("No human activation")
		quit(1)
		return
	var f: Figure = c.activatable()[0]
	var v: FigureView = scene.player.views[f.id]
	scene.floor_choice.select(scene.layout.index_of(f.surface_id))
	scene.refresh()
	var screen: Vector2 = scene.rig.camera.unproject_position(v.position+Vector3.UP*0.8)
	if not scene.controls.tap_figure(screen):
		printerr("Cannot activate human figure")
		quit(1)
		return
	scene.player._queue.clear()
	scene.refresh()
	if c.state.active()!=f or scene.targets.is_empty():
		printerr("No floor-specific move highlights")
		quit(1)
		return
	var node: Vector3i = scene.targets.keys()[0]
	scene.controls.choose_destination(node)
	if f.moves_taken!=1 or f.actions_left!=1:
		printerr("Movement command failed")
		quit(1)
		return
	print("Layered skirmish smoke passed")
	quit(0)
