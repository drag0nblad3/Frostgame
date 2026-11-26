extends Node3D
## Composition root for human-vs-bot play or optional bot-vs-bot observation.

const SCENARIO := "treasure_skirmish"
var _scenario_id := SCENARIO
var _active_scenario_id := SCENARIO
var _briefing: ScenarioDialog
var _inspector: FigureInspector
var _guide: AcceptDialog
var _training := -1
var _training_complete := false
var _training_failed := false
var _training_prompt: AcceptDialog
## Pause between bot activations in Auto mode (seconds).
const AUTO_DELAY := 0.35

var controller: GameController
var player: EventPlayer
var hud: BattleHud
var auto_play := false
var watch_mode := false
var player_side := 0
var player_input: BattleInput
var _markers: BattleMarkers
var _sites: ScenarioMarkers
var _dirty := true
var _roster: Dictionary = {}
var _setup: WarbandSetup
var _campaign := CampaignProgress.new()
var _campaign_battle := false
var _campaign_dialog: CampaignPanel
var _figures: FigureDb
var _terrain: TerrainDb
var _board_view: BoardView
var _atmosphere: BattleAtmosphere
var _rig: CameraRig
var _wait := 0.0


func _ready() -> void:
	_figures = FigureDb.load_files()
	_terrain = TerrainDb.load_file()
	_atmosphere = BattleAtmosphere.new()
	add_child(_atmosphere)
	_board_view = BoardView.new()
	add_child(_board_view)
	_rig = CameraRig.new()
	add_child(_rig)
	hud = BattleHud.new()
	add_child(hud)
	hud.step_pressed.connect(func() -> void:
		if watch_mode:
			step())
	hud.auto_toggled.connect(func(on: bool) -> void: auto_play = on)
	hud.watch_toggled.connect(set_watch_mode)
	hud.action_pressed.connect(_on_action)
	_briefing = ScenarioDialog.new()
	add_child(_briefing)
	_briefing.start_requested.connect(func() -> void:
		_campaign_battle = false
		new_game(0))
	hud.new_game_pressed.connect(func() -> void: _open_briefing(true))
	hud.briefing_pressed.connect(func() -> void: _open_briefing(false))
	_inspector = FigureInspector.new()
	add_child(_inspector)
	hud.inspect_pressed.connect(_open_inspector)
	hud.guide_pressed.connect(_open_guide)
	hud.atmosphere_toggled.connect(func() -> void:
		_atmosphere.set_effects(not _atmosphere.enabled)
		hud.notify("Snow effects %s." % ("on" if _atmosphere.enabled else "off")))
	hud.training_requested.connect(_confirm_training)
	hud.training_next.connect(_next_training)
	hud.training_retry.connect(func() -> void:
		if _training >= 0 and player.idle():
			_start_training(_training))
	hud.training_leave.connect(_leave_training)
	hud.roster_pressed.connect(_open_roster)
	hud.campaign_pressed.connect(_open_campaign)
	hud.save_battle_pressed.connect(_save_battle)
	hud.resume_battle_pressed.connect(_resume_battle)
	hud.scenario_selected.connect(func(id: String) -> void:
		_scenario_id = id
		hud.notify("Next battle: " + ScenarioBriefing.title(id)))
	_campaign.load_save()
	_rig.tapped.connect(_on_tap)
	_markers = BattleMarkers.new()
	add_child(_markers)
	_sites = ScenarioMarkers.new()
	add_child(_sites)
	new_game(0)


func _confirm_training() -> void:
	if _training_prompt == null:
		_training_prompt = AcceptDialog.new()
		_training_prompt.title = "Practice in the Training Yard"
		_training_prompt.dialog_text = "Four short lessons teach movement, treasure, combat and magic. Training replaces the current battle, but never changes your campaign. Save your battle first if needed."
		_training_prompt.exclusive = true
		_training_prompt.get_ok_button().text = "Start training"
		_training_prompt.confirmed.connect(func() -> void: _start_training(0))
		add_child(_training_prompt)
	_training_prompt.popup_centered(Vector2i(500, 240))


func _start_training(index: int) -> void:
	_training = index
	_training_complete = false
	_training_failed = false
	_campaign_battle = false
	watch_mode = false
	_active_scenario_id = "training_yard"
	var s := TrainingLesson.build(index, _figures, _terrain)
	s.reaction_side = player_side
	_rig.distance = 23.0
	_attach_battle(GameController.new(s, Dice.new(1)), true)


func _next_training() -> void:
	if _training < 0 or not _training_complete or not player.idle():
		return
	if _training + 1 < TrainingLesson.NAMES.size():
		_start_training(_training + 1)
	else:
		_leave_training()
		hud.notify("Training complete. You are ready for a skirmish!")


func _leave_training() -> void:
	if _training < 0 or not player.idle():
		return
	_scenario_id = SCENARIO
	hud.select_scenario(SCENARIO)
	new_game(0)


func _open_inspector() -> void:
	if controller == null or not player.idle():
		return
	_inspector.open(controller.state, controller.state.active_id)


func _open_guide() -> void:
	if _guide == null:
		_guide = AcceptDialog.new()
		_guide.title = "Field guide"
		_guide.exclusive = true
		_guide.theme = BattleTheme.create()
		var body := RichTextLabel.new()
		body.text = FieldGuide.OVERVIEW
		body.fit_content = false
		body.scroll_active = true
		body.add_theme_font_size_override("normal_font_size", 20)
		var viewport := get_viewport().get_visible_rect().size
		body.custom_minimum_size = Vector2(minf(600, viewport.x * 0.78), minf(380, viewport.y * 0.60))
		_guide.add_child(body)
		add_child(_guide)
	_guide.popup_centered()


func _info_open() -> bool:
	return (_training_prompt != null and _training_prompt.visible) or (_briefing != null and _briefing.visible) or (_inspector != null and _inspector.visible) or (_guide != null and _guide.visible)


func _open_briefing(start: bool) -> void:
	if _training >= 0 and not start:
		hud.notify(TrainingLesson.HINTS[_training])
		return
	_briefing.show_briefing(_scenario_id if start else _active_scenario_id, controller.state if controller != null else null, start)


func new_game(seed_value: int) -> void:
	if _training >= 0:
		_rig.distance = 34.0
	_training = -1
	_training_complete = false
	_training_failed = false
	hud.set_training(-1, false)
	_active_scenario_id = _scenario_id
	var data: Dictionary = JsonFile.read(ScenarioLoader.DIR + _scenario_id + ".json")
	if _campaign_battle:
		data["warbands"][0] = _campaign.deployment()
	elif not _roster.is_empty():
		data["warbands"][0] = _roster.duplicate(true)
	var state := ScenarioLoader.from_dict(data, _figures, _terrain)
	state.reaction_side = -2 if watch_mode else player_side
	_attach_battle(GameController.new(state, Dice.new(seed_value)), true)


func _attach_battle(c: GameController, start: bool) -> void:
	if player != null:
		player.queue_free()
	_markers.clear()
	auto_play = false
	hud.set_auto(false)
	_wait = 0.0
	controller = c
	var state := c.state
	_board_view.scenario_id = _active_scenario_id
	_board_view.build(state.board)
	_atmosphere.configure(state.board, _active_scenario_id)
	_sites.reset()
	_sites.update_sites(state)
	_markers.board = state.board
	_rig.look_at_table(TableSpace.to_world(state.board.size * 0.5))
	player = EventPlayer.new()
	player.state = state
	add_child(player)
	for f in state.figures:
		var v := FigureView.new()
		player.add_child(v)
		v.setup(f, "Creature" if f.side < 0 else state.side_names[f.side])
		v.face_toward(TableSpace.to_world(state.board.size * 0.5, f.elevation))
		player.views[f.id] = v
		v.set_active(f.id == state.active_id)
		if f.out_of_action:
			v.take_out()
		if f.exited:
			v.visible = false
	player.build_treasures()
	hud.clear_log()
	player.line_logged.connect(hud.add_line)
	player.notice.connect(hud.notify)
	player.roll_resolved.connect(hud.show_roll)
	controller.event_emitted.connect(player.push)
	controller.event_emitted.connect(_on_event)
	player_input = BattleInput.new(controller, hud, _rig.camera, _markers)
	if start:
		controller.start_game()
	else:
		for event in controller.history.slice(-8):
			var line := Explainer.text(state, event)
			if line != "":
				hud.add_line(line)
	_update_status()
	_dirty = true


## Plays one bot activation for whichever side is to move.
func step() -> void:
	if controller.state.over or not player.idle() or controller.awaiting_reaction():
		return
	if controller.state.active() != null:
		Bot.resume_activation(controller)
	else:
		Bot.play_activation(controller)
	_update_status()


func _process(delta: float) -> void:
	if _info_open() or (_campaign_dialog != null and _campaign_dialog.visible) or (_setup != null and _setup.visible) or controller == null or not player.idle():
		_wait = 0.0
		return
	if _training >= 0:
		_training_complete = TrainingLesson.completed(_training, controller)
		_training_failed = not _training_complete and (controller.state.over or not controller.state.figure(1).in_play() or controller.state.figure(1).activated)
		hud.set_training(_training, _training_complete, _training_failed)
	if _dirty:
		_refresh()
	if _training >= 0 and (_training_complete or _training_failed):
		_wait = 0.0
		return
	var s := controller.state
	if s.over and _campaign_battle:
		_campaign_battle = false
		_campaign.settle(controller, controller.dice)
		if _campaign.save():
			var checkpoint := BattleSnapshot.read()
			if checkpoint.get("meta", {}).get("campaign", false):
				DirAccess.remove_absolute(BattleSnapshot.PATH)
		_open_campaign()
	if s.over or controller.awaiting_reaction() or (watch_mode and not auto_play) or (not watch_mode and s.current_side() == player_side and (s.active() == null or s.active().side >= 0)):
		_wait = 0.0
		return
	_wait += delta
	if _wait >= AUTO_DELAY:
		_wait = 0.0
		step()


func set_watch_mode(on: bool) -> void:
	if _training >= 0 or controller.state.active() != null or controller.state.group.in_progress() or controller.awaiting_reaction() or not player.idle():
		hud.set_watch(watch_mode, false, false)
		return
	watch_mode = on
	controller.state.reaction_side = -2 if on else player_side
	auto_play = false
	hud.set_auto(false)
	_dirty = true


func _human_turn() -> bool:
	return not (_training >= 0 and (_training_complete or _training_failed)) and not _info_open() and (_setup == null or not _setup.visible) and not watch_mode and not controller.state.over and ((controller.state.current_side() == player_side and (controller.state.active() == null or controller.state.active().side >= 0)) or controller.awaiting_reaction())


func _on_event(event: GameEvent) -> void:
	if event.type == "terrain_changed":
		_board_view.build(controller.state.board)
	_dirty = true


func _refresh() -> void:
	_dirty = false
	_sites.update_sites(controller.state)
	_update_status()
	hud.set_watch(watch_mode, controller.state.active() == null and not controller.state.group.in_progress() and not controller.awaiting_reaction(), true)
	if _human_turn():
		player_input.refresh()
	else:
		player_input.lock("Battle complete." if controller.state.over else ("Watch mode · Step or Auto." if watch_mode else "Rival warband is acting."))


func _lock_after_action() -> void:
	player_input.lock("Resolving action…")
	hud.set_watch(watch_mode, false, false)
	_update_status()
	_dirty = true


func _on_action(key: String) -> void:
	if _human_turn() and player.idle() and not _dirty:
		if player_input.action(key):
			_lock_after_action()


func _on_tap(at: Vector2) -> void:
	if _human_turn() and player.idle() and not _dirty and not hud.blocks_tap(at):
		if player_input.tap(at):
			_lock_after_action()


func _update_status() -> void:
	var s := controller.state
	hud.set_objective(("Training Yard" if _training >= 0 else ScenarioBriefing.title(_active_scenario_id)) + " | " + ScenarioBriefing.progress(s))
	hud.set_training(_training, _training_complete, _training_failed)
	var score := ""
	for side in s.side_count():
		score += "  |  %s: %d" % [s.side_names[side], s.secured_count(side)]
	if s.pending_initiative:
		hud.set_status("Turn %d · Initiative choice%s" % [s.turn, score])
		return
	if s.over:
		var result := "Draw" if s.winner < 0 else "%s win" % s.side_names[s.winner]
		hud.set_status("Turn %d — %s%s" % [s.turn, result, score])
		return
	hud.set_status("Turn %d · %s · %s%s" % [s.turn, Phase.name_of(s.phase), ("Creatures" if s.current_side() < 0 else s.side_names[s.current_side()]), score])


func _open_roster() -> void:
	if _setup == null:
		_setup = WarbandSetup.new()
		add_child(_setup)
		_setup.setup(_figures)
		_setup.drafted.connect(func(roster: Dictionary) -> void:
			_roster = roster
			_campaign_battle = false
			watch_mode = false
			new_game(0))
	_setup.popup_centered_ratio(0.9)


func _open_campaign() -> void:
	if _campaign_dialog == null:
		_campaign_dialog = CampaignPanel.new()
		add_child(_campaign_dialog)
		_campaign_dialog.setup(_campaign, _figures)
		_campaign_dialog.begin_requested.connect(_begin_campaign_battle)
		_campaign_dialog.start_requested.connect(_create_campaign)
		_campaign_dialog.restart_requested.connect(_restart_campaign)
	_campaign_dialog.refresh(_campaign_battle)
	_campaign_dialog.popup_centered_ratio(0.85)


func _create_campaign() -> void:
	if not _campaign.data.is_empty():
		return
	var roster := _roster
	if roster.is_empty():
		var draft := WarbandDraft.new(_figures)
		draft.choose_defaults()
		roster = draft.as_warband()
	_campaign.start(roster)
	_campaign.save()
	_campaign_dialog.refresh(false)


func _restart_campaign() -> void:
	if _campaign_battle:
		return
	_campaign.data = {}
	_create_campaign()


func _begin_campaign_battle() -> void:
	if _campaign_battle or not _campaign.can_deploy():
		return
	for unit: Dictionary in _campaign.data["units"]:
		if InjuryRules.blind(unit) and not unit["dead"]:
			unit["dead"] = true
			CampaignInventory.lose_owned(_campaign.data, int(unit["id"]))
			_campaign.data["last_report"].append("%s retires after losing both eyes." % str(unit["type"]).capitalize())
	if not _campaign.save():
		return
	_campaign_battle = true
	watch_mode = false
	_campaign_dialog.hide()
	new_game(0)



func _campaign_fingerprint() -> String:
	return FileAccess.get_sha256(CampaignProgress.PATH) if FileAccess.file_exists(CampaignProgress.PATH) else ""


func _save_battle() -> void:
	if _training >= 0:
		hud.notify("Training does not replace your saved battle.")
		return
	if controller == null or not player.idle() or not BattleSnapshot.can_save(controller):
		hud.notify("Finish the current roll or animation before saving.")
		return
	var meta := {"scenario": _active_scenario_id, "campaign": _campaign_battle, "campaign_hash": _campaign_fingerprint() if _campaign_battle else "", "watch": watch_mode}
	if BattleSnapshot.save(controller, meta):
		hud.notify("Battle saved.")
	else:
		hud.notify("Could not save this battle.")


func _resume_battle() -> void:
	if controller != null and not player.idle():
		hud.notify("Finish the current animation before resuming.")
		return
	var data := BattleSnapshot.read()
	if data.is_empty():
		hud.notify("No compatible saved battle.")
		return
	var meta: Dictionary = data.get("meta", {})
	if meta.get("campaign", false) and (meta.get("campaign_hash", "") == "" or meta["campaign_hash"] != _campaign_fingerprint()):
		hud.notify("Campaign changed since this checkpoint; cannot resume it.")
		return
	var restored := BattleSnapshot.rebuild(data, _figures)
	if restored == null:
		hud.notify("Could not restore the saved battle.")
		return
	if _training >= 0:
		_rig.distance = 34.0
	_training = -1
	_training_complete = false
	_training_failed = false
	hud.set_training(-1, false)
	_scenario_id = str(meta.get("scenario", SCENARIO))
	_active_scenario_id = _scenario_id
	hud.select_scenario(_scenario_id)
	_campaign_battle = bool(meta.get("campaign", false))
	watch_mode = bool(meta.get("watch", false))
	_attach_battle(restored, false)
	hud.notify("Battle resumed.")
