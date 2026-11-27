class_name BattleScene
extends Node3D
## Composition root for human-vs-bot play or optional bot-vs-bot observation.

const SCENARIO := "treasure_skirmish"
var _scenario_id := SCENARIO
var _active_scenario_id := SCENARIO
var _briefing: ScenarioDialog
var _inspector: FigureInspector
var _guide: FieldGuideDialog
var _training := -1
var _training_complete := false
var _training_failed := false
var _training_prompt: AcceptDialog
## Pause between bot activations in Auto mode (seconds).
const AUTO_DELAY := 0.8

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
var _terrain_pending := false
var _graphics: GraphicsDialog
var _roster: Dictionary = {}
var _setup: WarbandSetup
var _campaign := CampaignProgress.new()
var _campaign_battle := false
var _expedition_checkpoint_stamp := ""
var _campaign_dialog: CampaignPanel
var _plant_dialog: ConfirmationDialog
var _survival_dialog: ConfirmationDialog
var _figures: FigureDb
var _terrain: TerrainDb
var _board_view: BoardView
var _atmosphere: BattleAtmosphere
var _rig: CameraRig
var _wait := 0.0
var _bots := BotRunner.new()
var _launch_intent := ""
var _title_prompt: AcceptDialog
var _picker: SkirmishPicker
var _move_preview_tween: Tween
var _visible_floor := ""
var _floor_revision := 0
var _deployment_panel: BattleDeploymentPanel


func _ready() -> void:
	GraphicsQuality.apply(get_viewport())
	var profile := WarbandSlots.content_profile()
	_figures = FigureDb.load_files(FigureDb.FIGURES,FigureDb.WEAPONS,profile)
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
	hud.floor_selected.connect(_select_floor)
	_briefing = ScenarioDialog.new()
	add_child(_briefing)
	_briefing.start_requested.connect(func() -> void:
		_campaign_battle = false
		new_game(0,null,true))
	hud.new_game_pressed.connect(_open_map_picker)
	hud.briefing_pressed.connect(func() -> void: _open_briefing(false))
	_inspector = FigureInspector.new()
	add_child(_inspector)
	hud.inspect_pressed.connect(_open_inspector)
	hud.guide_pressed.connect(_open_guide)
	hud.journal_requested.connect(_open_journal)
	hud.graphics_requested.connect(_open_graphics)
	hud.atmosphere_toggled.connect(func() -> void:
		_atmosphere.set_effects(not _atmosphere.enabled)
		hud.notify("Snow effects %s." % ("on" if _atmosphere.enabled else "off")))
	hud.camera_requested.connect(_camera_preset)
	hud.presentation_changed.connect(_presentation_changed)
	hud.title_requested.connect(_confirm_title)
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
	hud.resume_expedition_pressed.connect(func() -> void: BattleCampaignFlow._resume_battle(self,true))
	hud.scenario_selected.connect(func(id: String) -> void:
		if not _figures.content_profile.allows("scenarios",id):
			return
		_scenario_id = id
		hud.notify("Next battle: " + ScenarioBriefing.title(id)))
	_campaign.load_save()
	if not _campaign.data.is_empty():
		_campaign.data["expansions"]=profile.enabled.duplicate()
	_roster=WarbandSlots.roster()
	if get_tree().root.has_meta("frostgame_scenario"):
		_scenario_id=str(get_tree().root.get_meta("frostgame_scenario"))
		get_tree().root.remove_meta("frostgame_scenario")
		if not ScenarioBriefing.available_entries(profile).has(_scenario_id):
			_scenario_id=SCENARIO
		hud.select_scenario(_scenario_id)
	_rig.tapped.connect(_on_tap)
	_rig.plan_drag.connect(_on_plan_drag)
	_rig.can_plan_drag=_can_plan_drag
	_markers = BattleMarkers.new()
	add_child(_markers)
	_sites = ScenarioMarkers.new()
	add_child(_sites)
	if get_tree().root.has_meta("frostgame_launch"):
		_launch_intent = str(get_tree().root.get_meta("frostgame_launch"))
		get_tree().root.remove_meta("frostgame_launch")
	if get_tree().root.has_meta("layered_board"):
		var id:=str(get_tree().root.get_meta("layered_board"))
		get_tree().root.remove_meta("layered_board")
		var layered:=LayeredCheckpoint.load_battle(_figures) if bool(get_tree().root.get_meta("layered_resume",false)) else null
		get_tree().root.remove_meta("layered_resume")
		if layered==null:
			layered=LayeredBattle.create(_figures,_terrain,17,id)
		layered.state.reaction_side=player_side
		_active_scenario_id="silent_tower" if layered.state.board.id=="layered_silent_tower" else "treasure_skirmish"
		_attach_battle(layered,false)
	elif _launch_intent=="training":
		_launch_intent=""
		_start_training(0)
	elif _launch_intent=="resume":
		_launch_intent=""
		_resume_battle()
		if controller==null:
			new_game(0)
	else:
		new_game(0,null,_launch_intent=="selected_skirmish")


func _open_launch_intent() -> void:
	var intent := _launch_intent
	_launch_intent = ""
	match intent:
		"resume": _resume_battle()
		"warband": _open_roster()
		"campaign": _open_campaign()
		"training": _start_training(0)
		"guide": _open_guide()
		"skirmish": _open_map_picker()
		"selected_skirmish": pass # Confirmed in the full-screen battlefield catalogue.


func _confirm_title() -> void:
	if not player.idle():
		hud.notify("Finish the current animation before leaving.")
		return
	if _title_prompt == null:
		_title_prompt = AcceptDialog.new()
		_title_prompt.title = "Return home?"
		_title_prompt.dialog_text = "Save this battle in the active warband slot before leaving, or leave without saving."
		_title_prompt.exclusive = true
		_title_prompt.get_ok_button().text = "Leave without saving"
		_title_prompt.add_cancel_button("Stay here")
		_title_prompt.add_button("Save & Home",true,"save_home")
		_title_prompt.custom_action.connect(func(action: StringName) -> void:
			if action=="save_home" and _save_battle():
				_title_prompt.hide()
				get_tree().change_scene_to_file("res://scenes/title.tscn"))
		_title_prompt.confirmed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/title.tscn"))
		add_child(_title_prompt)
	PhoneSafeArea.popup_dialog(_title_prompt,Vector2(500,220))


func _confirm_training() -> void:
	BattleTraining._confirm_training(self)


func _start_training(index: int) -> void:
	BattleTraining._start_training(self, index)


func _next_training() -> void:
	BattleTraining._next_training(self)


func _leave_training() -> void:
	BattleTraining._leave_training(self)


func _presentation_changed(speed: float,cinematic: bool) -> void:
	if player!=null:
		player.speed=speed
		player.camera_director.enabled=cinematic
		if not cinematic:
			player.camera_director.finish()


func _camera_preset(mode: int) -> void:
	if controller == null:
		return
	var s := controller.state
	if mode == 2:
		var f := s.active()
		if f != null:
			_rig.focus_figure(TableSpace.to_world(f.pos, f.elevation + 0.7))
			return
	_rig.frame_board(s.board.size, mode == 1)


func _open_inspector() -> void:
	if controller == null or not player.idle():
		return
	_inspector.open(controller.state, controller.state.active_id)


func _open_journal() -> void:
	if controller==null or player==null or _bots.busy() or not player.idle():
		hud._open_journal()
		return
	hud._open_journal(BattleTimeline.build(controller.state,controller.history),controller.replay_frames.duplicate(true))


func _open_guide() -> void:
	if _guide==null:
		_guide=FieldGuideDialog.new()
		add_child(_guide)
	_guide.open("Return to battle")


func _info_open() -> bool:
	return ModalInput.blocked() or (_graphics!=null and _graphics.visible) or (_picker != null and _picker.visible) or (_title_prompt != null and _title_prompt.visible) or (_training_prompt != null and _training_prompt.visible) or (_briefing != null and _briefing.visible) or (_inspector != null and _inspector.visible) or (_guide != null and _guide.visible)


func _open_briefing(start: bool) -> void:
	if _training >= 0 and not start:
		hud.notify(TrainingLesson.HINTS[_training])
		return
	_briefing.show_briefing(_scenario_id if start else _active_scenario_id, controller.state if controller != null else null, start)


func new_game(seed_value: int,prepared: GameState=null,deploy: bool=false) -> void:
	if not ScenarioBriefing.available_entries(_figures.content_profile).has(_scenario_id):
		_scenario_id=SCENARIO
	if _training >= 0:
		_rig.distance = 34.0
	_training = -1
	_training_complete = false
	_training_failed = false
	hud.set_training(-1, false)
	_active_scenario_id = _scenario_id
	var began := Time.get_ticks_usec()
	var state := prepared
	if state==null:
		var data: Dictionary = JsonFile.read(ScenarioLoader.DIR + _scenario_id + ".json")
		if _campaign_battle:
			data["warbands"][0] = _campaign.deployment()
			data["reality_cracks"]=_campaign.data.get("reality_cracks",false)
		elif not _roster.is_empty():
			data["warbands"][0] = _roster.duplicate(true)
		state=ScenarioLoader.from_dict(data,_figures,_terrain)
	print("Map load: rules state %.1f ms (reused=%s)"%[float(Time.get_ticks_usec()-began)/1000.0,prepared!=null])
	state.reaction_side = -2 if watch_mode else player_side
	var game:=GameController.new(state,Dice.new(seed_value))
	if deploy:
		# Headless smoke runs use the same automatic placement, never a blocking UI.
		var interactive:=not watch_mode and DisplayServer.get_name()!="headless"
		var setup:=game.begin_deployment(player_side if interactive else -1)
		_attach_battle(game,setup.done)
		if not setup.done:
			_rig.frame_board(state.board.size)
			_deployment_panel=BattleDeploymentPanel.new()
			add_child(_deployment_panel)
			_deployment_panel.open(self)
			player_input.lock("Deploy your warband before Turn 1.")
		return
	_attach_battle(game,true)


func _attach_battle(c: GameController, start: bool) -> void:
	if is_instance_valid(_deployment_panel):
		_deployment_panel.queue_free()
		_deployment_panel=null
	if _move_preview_tween!=null and _move_preview_tween.is_valid():
		_move_preview_tween.kill()
	if player != null:
		_rig.manual_camera()
		remove_child(player)
		player.queue_free()
	_markers.clear()
	auto_play = false
	hud.set_auto(false)
	_wait = 0.0
	_bots.finish()
	controller = c
	controller.capture_frames=true
	if controller.deployment==null or controller.deployment.done:
		BattleFrame.record(controller)
	_expedition_checkpoint_stamp=""
	var state := c.state
	var began := Time.get_ticks_usec()
	_board_view.scenario_id = _active_scenario_id
	_board_view.build(state.board)
	print("Map load: %s terrain %.1f ms"%[_active_scenario_id,float(Time.get_ticks_usec()-began)/1000.0])
	_atmosphere.configure(state.board, _active_scenario_id)
	_sites.reset()
	_sites.update_sites(state)
	_markers.board = state.board
	_rig.look_at_table(TableSpace.to_world(state.board.size * 0.5))
	player = EventPlayer.new()
	player.state = state
	player.camera_director.rig=_rig
	player.speed=BattleHud.PACE_SPEEDS[hud._pace]
	player.camera_director.enabled=hud._cinematic
	add_child(player)
	var figures_started:=Time.get_ticks_usec()
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
	print("Map load: %d miniatures %.1f ms"%[state.figures.size(),float(Time.get_ticks_usec()-figures_started)/1000.0])
	player.build_treasures()
	hud.clear_log()
	player.line_logged.connect(hud.add_line)
	player.notice.connect(hud.notify)
	player.outcome.connect(hud.show_outcome)
	player.roll_resolved.connect(hud.show_roll)
	controller.event_emitted.connect(_relay)
	player_input = BattleInput.new(controller, hud, _rig.camera, _markers)
	player_input.move_preview_changed.connect(_move_preview)
	_visible_floor=""
	_floor_revision=state.board.floor_layout.hash()
	hud.set_floors(FloorLayout.from_dict(state.board.floor_layout) if not state.board.floor_layout.is_empty() else null)
	if not state.board.floor_layout.is_empty():
		_rig.frame_board(state.board.size)
	if start:
		controller.start_game()
	else:
		for event in controller.history.slice(-BattleJournal.LIMIT):
			var line := Explainer.text(state,event)
			if not line.is_empty():
				hud.add_line(line)
			var roll := RollSummary.describe(state,event)
			BattleJournal.record(hud._history,roll)
	_update_status()
	_dirty = true
	print("Map load: %s playable scene attached %.1f ms"%[_active_scenario_id,float(Time.get_ticks_usec()-began)/1000.0])


func _deployment_complete() -> void:
	if controller.deployment==null or not controller.deployment.done:
		return
	if is_instance_valid(_deployment_panel):
		_deployment_panel.hide()
		_deployment_panel.queue_free()
		_deployment_panel=null
	_markers.clear()
	for f in controller.state.figures:
		var v: FigureView=player.views.get(f.id)
		if v!=null:
			v.visible=f.in_play()
			v.position=TableSpace.to_world(f.pos,f.elevation)
			v.set_active(false)
	BattleFrame.record(controller)
	controller.start_game()
	_dirty=true


## Plays one bot activation for whichever side is to move.
func step() -> void:
	if is_instance_valid(_deployment_panel) or ModalInput.blocked():
		return
	if controller.state.over or not player.idle() or controller.awaiting_reaction():
		return
	_bots.start(controller)
	if _bots.busy():
		player.thinking = true
		player_input.lock("Rival warband is thinking…")
	else:
		_update_status()


## Bot events arrive on a worker thread; hold them until it finishes.
func _relay(event: GameEvent) -> void:
	if _bots.capture(event):
		return
	player.push(event)
	_on_event(event)


func _collect_bot_turn() -> void:
	player.thinking = false
	for event in _bots.take_events():
		player.push(event)
		_on_event(event)
	_update_status()


func _process(delta: float) -> void:
	if _bots.busy():
		if not _bots.done():
			return
		_collect_bot_turn()
	if ModalInput.blocked():
		_rig.cancel_gesture()
	if is_instance_valid(_deployment_panel):
		return
	if not _launch_intent.is_empty() and controller!=null and not ModalInput.blocked():
		_open_launch_intent()
		return
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
		if is_instance_valid(_survival_dialog):
			return
		var candidates := RedKingCampaignGear.plant_choices(_campaign.data,controller,0)
		if candidates.is_empty():
			_finish_campaign_battle(-1)
		else:
			_choose_plant(candidates)
		return
	if s.over or controller.awaiting_reaction() or (watch_mode and not auto_play) or (not watch_mode and s.current_side() == player_side and (s.active() == null or s.active().side >= 0)):
		_wait = 0.0
		return
	_wait += delta
	if _wait >= AUTO_DELAY:
		_wait = 0.0
		step()


func set_watch_mode(on: bool) -> void:
	if is_instance_valid(_deployment_panel):
		hud.set_watch(watch_mode,false,false)
		return
	if _training >= 0 or controller.state.active() != null or controller.state.group.in_progress() or controller.awaiting_reaction() or not player.idle():
		hud.set_watch(watch_mode, false, false)
		return
	watch_mode = on
	controller.state.reaction_side = -2 if on else player_side
	auto_play = false
	hud.set_auto(false)
	_dirty = true


func _human_turn() -> bool:
	return not is_instance_valid(_deployment_panel) and not (_training >= 0 and (_training_complete or _training_failed)) and not _info_open() and (_setup == null or not _setup.visible) and not watch_mode and not controller.state.over and ((controller.state.current_side() == player_side and (controller.state.active() == null or controller.state.active().side >= 0)) or controller.awaiting_reaction())


func _on_event(event: GameEvent) -> void:
	if event.type in ["terrain_changed","boundary_changed","floor_layout_changed"] and not _terrain_pending:
		_terrain_pending=true
		call_deferred("_sync_terrain")
	_dirty = true


func _refresh() -> void:
	BattleFrame.record(controller)
	_dirty = false
	_sites.update_sites(controller.state)
	_update_status()
	hud.set_watch(watch_mode, controller.state.active() == null and not controller.state.group.in_progress() and not controller.awaiting_reaction(), true)
	if _human_turn():
		player_input.refresh()
	else:
		player_input.lock("Battle complete." if controller.state.over else ("Watch mode · Step or Auto." if watch_mode else "Rival warband is acting."))
	_update_floor_view()
	_checkpoint_expedition()


func _checkpoint_expedition() -> void:
	if not _campaign_battle or not player.idle() or not BattleSnapshot.can_save(controller):
		return
	var s := controller.state
	var stamp := "%s:%s"%[s.turn,s.phase]
	if stamp==_expedition_checkpoint_stamp:
		return
	if CampaignBattleCheckpoint.save(controller,_active_scenario_id,_campaign_fingerprint(),watch_mode):
		_expedition_checkpoint_stamp=stamp


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
	if is_instance_valid(_deployment_panel):
		if not _info_open() and not hud.blocks_tap(at):
			_deployment_panel.tap(at)
		return
	if _human_turn() and player.idle() and not _dirty and not hud.blocks_tap(at):
		if player_input.tap(at):
			_lock_after_action()


func _can_plan_drag(at: Vector2) -> bool:
	return controller!=null and player_input!=null and player.idle() and not _dirty and _human_turn() and not hud.blocks_tap(at) and player_input.move_plan.can_begin_drag(player_input,at)


func _on_plan_drag(at: Vector2) -> void:
	if controller!=null and player_input!=null and player.idle() and not _dirty and _human_turn() and not hud.blocks_tap(at):
		player_input.plan_drag(at)


func _select_floor(id: String) -> void:
	if controller==null or _bots.busy() or not player.idle() or controller.state.board.floor_layout.is_empty():
		return
	_visible_floor=id
	if _human_turn() and not _dirty:
		player_input.select_floor(id)
	else:
		player_input.floor_id=id
	_update_floor_view()


func _update_floor_view() -> void:
	if controller.state.board.floor_layout.is_empty() or not player.idle():
		return
	var layout:=FloorLayout.from_dict(controller.state.board.floor_layout)
	var revision:=controller.state.board.floor_layout.hash()
	if revision!=_floor_revision:
		_floor_revision=revision
		if layout.index_of(_visible_floor)<0:
			_visible_floor=""
		hud.set_floors(layout,_visible_floor)
	_board_view.show_floor(layout,_visible_floor)
	for f in controller.state.figures:
		if not player.views.has(f.id):
			continue
		var surface:=f.surface_id
		if player_input.move_plan.actor==f.id and player_input.move_plan.destination is Vector3i:
			surface=layout.surface_id(player_input.move_plan.destination)
		player.views[f.id].visible=f.in_play() and (_visible_floor.is_empty() or _visible_floor==surface)
	for t in controller.state.treasures:
		if not player.treasure_views.has(t.id):
			continue
		var carrier:=controller.state.figure(t.carrier_id)
		var surface:=carrier.surface_id if carrier!=null else t.surface_id
		player.treasure_views[t.id].visible=t.unresolved() and (_visible_floor.is_empty() or _visible_floor==surface)


func _move_preview(id: int,at: Vector3,active: bool) -> void:
	if not player.views.has(id):
		return
	var f := controller.state.figure(id)
	if f==null:
		return
	var view: FigureView=player.views[id]
	# Only presentation moves. Interpolate nearby drag updates; snap on a
	# distant tap rather than animating through walls. Undo always restores
	# the exact authoritative position before event animations begin.
	if _move_preview_tween!=null and _move_preview_tween.is_valid():
		_move_preview_tween.kill()
	var point := at if active else TableSpace.to_world(f.pos,f.elevation)
	if active and view.position.distance_to(point)<=1.25:
		_move_preview_tween=create_tween()
		_move_preview_tween.tween_property(view,"position",point,0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:
		view.position=point
	_update_floor_view()


func _update_status() -> void:
	var s := controller.state
	if controller.deployment!=null and not controller.deployment.done:
		hud.set_status("Deployment · before Turn 1")
		return
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
		_setup.setup(_figures,_roster)
		_setup.drafted.connect(func(roster: Dictionary) -> void:
			if not WarbandSlots.save_roster(roster):
				hud.notify("Could not save warband.")
				return
			_roster = roster
			_campaign_battle = false
			watch_mode = false
			new_game(0,null,true))
	_setup.open("Save & deploy")


func _open_campaign() -> void:
	BattleCampaignFlow._open_campaign(self)


func _create_campaign() -> void:
	BattleCampaignFlow._create_campaign(self)


func _create_story_campaign(include_veil: bool,strict_pursuit: bool) -> void:
	BattleCampaignFlow._create_story_campaign(self, include_veil, strict_pursuit)


func _restart_campaign() -> void:
	BattleCampaignFlow._restart_campaign(self)


func _begin_campaign_battle() -> void:
	BattleCampaignFlow._begin_campaign_battle(self)


func _campaign_fingerprint() -> String:
	var path := WarbandSlots.path_for(CampaignProgress.PATH)
	return FileAccess.get_sha256(path) if FileAccess.file_exists(path) else ""


func _save_battle() -> bool:
	return BattleCampaignFlow._save_battle(self)


func _resume_battle() -> void:
	BattleCampaignFlow._resume_battle(self)


func _open_map_picker() -> void:
	if not player.idle():
		hud.notify("Finish the current action before choosing a scenario.")
		return
	if _picker==null:
		_picker=SkirmishPicker.new()
		add_child(_picker)
		_picker.selected.connect(func(id: String) -> void:
			_scenario_id=id
			hud.select_scenario(id)
			_campaign_battle=false
			watch_mode=false
			new_game(0,null,true))
	_picker.open(false)


func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_GO_BACK_REQUEST and is_inside_tree():
		if ModalInput.close_top(get_tree().root):
			return
		if is_instance_valid(player):
			_confirm_title()


func _sync_terrain() -> void:
	_terrain_pending=false
	if is_inside_tree() and controller!=null:
		_board_view.sync_terrain(controller.state.board)


func _open_graphics() -> void:
	if _graphics==null:
		_graphics=GraphicsDialog.new()
		add_child(_graphics)
		_graphics.quality_changed.connect(func() -> void:
			GraphicsQuality.apply(get_viewport())
			_atmosphere.configure(controller.state.board,_active_scenario_id))
	_graphics.open()


func _choose_plant(candidates: Array[int]) -> void:
	BattleCampaignFlow._choose_plant(self, candidates)


func _finish_campaign_battle(plant_target: int,survival_choice: int=-1) -> void:
	BattleCampaignFlow._finish_campaign_battle(self, plant_target, survival_choice)


func _choose_survival(plant_target: int,offer: Dictionary,rolled: bool) -> void:
	BattleCampaignFlow._choose_survival(self, plant_target, offer, rolled)


func _commit_survival(plant_target: int,choice: int) -> void:
	BattleCampaignFlow._commit_survival(self, plant_target, choice)
