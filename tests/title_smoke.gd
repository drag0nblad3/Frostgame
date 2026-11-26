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
	title_scene._buttons["guide"].pressed.emit()
	if current_scene!=title_scene or title_scene._guide==null or not title_scene._guide.visible or root.has_meta("frostgame_launch"):
		printerr("Field guide should open directly from home")
		quit(1)
		return
	if title_scene._guide._pages.size()<12 or title_scene._guide._body.text.is_empty():
		printerr("Field guide missing reference topics")
		quit(1)
		return
	title_scene._guide._show(1)
	if title_scene._guide._topics.selected!=1:
		printerr("Field guide topic navigation failed")
		quit(1)
		return
	if not ModalInput.blocked() or not title_scene._guide.exclusive or not title_scene._guide.transient:
		printerr("Guide is not modal")
		quit(1)
		return
	title_scene._buttons["training"].pressed.emit()
	if title_scene._launching or current_scene!=title_scene:
		printerr("Home navigation leaked behind guide")
		quit(1)
		return
	title_scene._notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	if title_scene._guide.visible or ModalInput.blocked():
		printerr("Android Back failed to close guide")
		quit(1)
		return
	title_scene._buttons["skirmish"].pressed.emit()
	if title_scene._picker==null or title_scene._picker._list.get_child_count()!=12:
		printerr("Standard scenario catalog incomplete")
		quit(1)
		return
	if title_scene._buttons.has("gatehouse") or title_scene._buttons.has("resume_layered"):
		printerr("Experimental maps exposed in player menu")
		quit(1)
		return
	title_scene._picker.hide()
	title_scene._buttons["warband"].pressed.emit()
	if title_scene._editor==null or not title_scene._editor.visible:
		printerr("Home warband editor missing")
		quit(1)
		return
	title_scene._editor.hide()
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
