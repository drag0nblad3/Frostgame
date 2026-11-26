extends SceneTree

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var original: GameController = scene.controller
	scene.hud.scenario_selected.emit("complex_temple")
	scene._open_briefing(false)
	if scene._briefing.title != "Frozen Ruins" or not scene._briefing.visible or scene.controller != original:
		_fail("Current briefing not tied to active battle")
		return
	scene._briefing.hide()
	scene._open_briefing(true)
	if scene._briefing.title != "The Complex Temple" or scene.controller != original:
		_fail("New scenario confirmation not tied to next battle")
		return
	scene._briefing.hide()
	scene._briefing.start_requested.emit()
	if scene.controller == original or scene.controller.state.scenario_special != "complex_temple":
		_fail("Confirmed scenario did not start")
		return
	if not scene.hud._objective.text.contains("Guardians 6"):
		_fail("Scenario progress not visible")
		return
	print("Scenario UI smoke passed: selection, briefing, confirmation and objectives")
	quit(0)


func _fail(reason: String) -> void:
	printerr(reason)
	quit(1)
