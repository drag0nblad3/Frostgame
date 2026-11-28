extends SceneTree

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var original: GameController = scene.controller
	scene.player.speed=30.0
	while not scene.player.idle():
		await process_frame
	scene._open_map_picker()
	if scene._picker==null or scene._picker._list.item_count!=12:
		_fail("Battle map catalog missing")
		return
	# Cycle every catalogue entry, including expansion maps, without changing the save.
	var picker: SkirmishPicker=scene._picker
	picker._entries=ScenarioBriefing.all_entries()
	picker._populate()
	var started := Time.get_ticks_msec()
	for i in picker._ids.size():
		picker._inspect(i)
		if picker._table._board!=picker._map._board or picker._table.get_child_count()!=0 or picker._boards.size()>4:
			_fail("Scenario preview constructed a scene or duplicated board data")
			return
		var cached: Board=picker._table._board
		picker._inspect(i)
		if picker._table._board!=cached:
			_fail("Repeated selection reloaded its board")
			return
		await process_frame
	print("Scenario catalogue cycle: %d entries, %d ms including frames"%[picker._ids.size(),Time.get_ticks_msec()-started])
	picker._entries=ScenarioBriefing.available_entries(WarbandSlots.content_profile())
	picker._populate()
	var index: int=scene._picker._ids.find("complex_temple")
	if index<0:
		_fail("Temple missing from catalogue")
		return
	scene._picker._inspect(index)
	if scene.controller!=original or scene._picker._chosen!="complex_temple" or not scene._picker.visible:
		_fail("Inspecting map changed current battle")
		return
	scene._picker.hide()
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
	scene._open_map_picker()
	scene._picker._inspect(scene._picker._ids.find("complex_temple"))
	scene._picker._start()
	if scene.controller == original or scene.controller.state.scenario_special != "complex_temple":
		_fail("Confirmed scenario did not start")
		return
	if scene._sites.get_child_count() != 6:
		_fail("Missing guardian markers")
		return
	if not scene.hud._objective.text.contains("Guardians 6"):
		_fail("Scenario progress not visible")
		return
	scene.player.speed = 30.0
	while not scene.player.idle():
		await process_frame
	scene._open_inspector()
	if not scene._inspector.visible or not scene._inspector._body.text.contains("Health"):
		_fail("Figure inspector unavailable")
		return
	if scene._inspector._portrait._model == null:
		_fail("Inspector miniature preview missing")
		return
	scene._inspector.hide()
	var before_guide: GameController=scene.controller
	scene._open_guide()
	if not scene._guide.visible or scene.controller!=before_guide or scene._guide._body.text.is_empty():
		_fail("Field guide unavailable")
		return
	var old_pitch: float=scene._rig.pitch
	var old_distance: float=scene._rig.distance
	var wheel := InputEventMouseButton.new()
	wheel.button_index=MOUSE_BUTTON_WHEEL_UP
	wheel.pressed=true
	scene._rig._unhandled_input(wheel)
	if not ModalInput.blocked() or not is_equal_approx(scene._rig.distance,old_distance) or not is_equal_approx(scene._rig.pitch,old_pitch):
		_fail("Camera received input behind guide")
		return
	scene._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	if scene._guide.visible or ModalInput.blocked() or scene.controller!=before_guide:
		_fail("Back did not dismiss guide safely")
		return
	scene.hud._open_commands()
	if not ModalInput.blocked() or not scene.hud._command_screen.visible or scene.hud._command_screen._buttons.size()!=21 or not scene.hud._command_screen._buttons.has(20):
		_fail("Battle command screen unavailable")
		return
	ModalInput.close_top(root)
	if ModalInput.blocked() or scene.controller!=before_guide:
		_fail("Closing command screen changed battle")
		return
	scene.hud.add_line("Journal event check")
	scene.hud.show_roll("Journal roll check")
	scene.hud._open_commands()
	scene.hud._command_screen._select(16)
	if not ModalInput.blocked() or not scene.hud._journal.visible or not scene.hud._journal._text.text.contains("Journal roll check") or not scene.hud._journal._text.text.contains("Journal event check"):
		_fail("Battle journal did not expose events and rolls")
		return
	ModalInput.close_top(root)
	if ModalInput.blocked() or scene.controller!=before_guide:
		_fail("Closing journal changed battle")
		return
	var cutaway_before: bool=scene._board_view.cutaway_enabled
	scene.hud._menu_action(20)
	if scene._board_view.cutaway_enabled==cutaway_before:
		_fail("Interior cutaway toggle unavailable")
		return
	scene.hud._menu_action(20)
	scene.hud._menu_action(17)
	if not is_equal_approx(scene.player.speed,1.6):
		_fail("Playback speed did not reach the director")
		return
	scene.hud._menu_action(18)
	if not scene.player.camera_director.enabled:
		_fail("Action camera toggle unavailable")
		return
	scene.hud._menu_action(18)
	scene.player.speed=30.0
	scene._camera_preset(1)
	if scene._rig.pitch < deg_to_rad(80.0):
		_fail("Overhead preset did not change camera")
		return
	scene._camera_preset(0)
	if scene._rig.pitch > deg_to_rad(60.0):
		_fail("Tabletop preset did not restore camera")
		return
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
