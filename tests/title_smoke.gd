extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	change_scene_to_file("res://scenes/title.tscn")
	await scene_changed
	var title_scene := current_scene
	if not title_scene._buttons.has("training") or not title_scene._buttons.has("campaign"):
		printerr("Title navigation missing")
		quit(1)
		return
	title_scene._buttons["training"].pressed.emit()
	await scene_changed
	var battle := current_scene
	for i in 240:
		if battle._training == 0:
			break
		await process_frame
	if battle._training != 0 or battle._active_scenario_id != "training_yard":
		printerr("Training launch failed")
		quit(1)
		return
	print("Title smoke passed")
	quit(0)
