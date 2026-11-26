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
	if scene._sites.get_child_count() != 6:
		_fail("Missing guardian markers")
		return
	if not scene.hud._objective.text.contains("Guardians 6"):
		_fail("Scenario progress not visible")
		return
	scene._open_inspector()
	if not scene._inspector.visible or not scene._inspector._body.text.contains("Health"):
		_fail("Figure inspector unavailable")
		return
	scene._inspector.hide()
	scene._open_guide()
	if not scene._guide.visible:
		_fail("Field guide unavailable")
		return
	scene._guide.hide()
	scene.player_input.available.assign(["items"])
	scene.player_input.item_options.assign(["weapon_staff"])
	scene.player_input.action("items")
	if scene.player_input.mode != "items_menu" or not scene.player_input.available.has("weapon_staff") or not scene.player_input.available.has("items_back"):
		_fail("Equipment menu did not expose its choices")
		return
	print("Scenario UI smoke passed: selection, briefing, confirmation, objectives, inspector, guide, equipment")
	quit(0)


func _fail(reason: String) -> void:
	printerr(reason)
	quit(1)
