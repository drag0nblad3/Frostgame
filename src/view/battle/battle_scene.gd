extends Node3D
## Composition root for human-vs-bot play or optional bot-vs-bot observation.

const SCENARIO := "treasure_skirmish"
var _scenario_id := SCENARIO
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
var _dirty := true
var _roster: Dictionary = {}
var _setup: WarbandSetup
var _campaign := CampaignProgress.new()
var _campaign_battle := false
var _campaign_dialog: CampaignPanel
var _figures: FigureDb
var _terrain: TerrainDb
var _board_view: BoardView
var _rig: CameraRig
var _wait := 0.0


func _ready() -> void:
	_figures = FigureDb.load_files()
	_terrain = TerrainDb.load_file()
	_add_lighting()
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
	hud.new_game_pressed.connect(func() -> void:
		_campaign_battle = false
		new_game(0))
	hud.roster_pressed.connect(_open_roster)
	hud.campaign_pressed.connect(_open_campaign)
	hud.scenario_selected.connect(func(id: String) -> void: _scenario_id = id)
	_campaign.load_save()
	_rig.tapped.connect(_on_tap)
	_markers = BattleMarkers.new()
	add_child(_markers)
	new_game(0)


func new_game(seed_value: int) -> void:
	if player != null:
		player.queue_free()
	_markers.clear()
	auto_play = false
	hud.set_auto(false)
	_wait = 0.0
	var data: Dictionary = JsonFile.read(ScenarioLoader.DIR + _scenario_id + ".json")
	if _campaign_battle:
		data["warbands"][0] = _campaign.deployment()
	elif not _roster.is_empty():
		data["warbands"][0] = _roster.duplicate(true)
	var state := ScenarioLoader.from_dict(data, _figures, _terrain)
	state.reaction_side = -2 if watch_mode else player_side
	controller = GameController.new(state, Dice.new(seed_value))
	_board_view.build(state.board)
	_markers.board = state.board
	_rig.look_at_table(TableSpace.to_world(state.board.size * 0.5))
	player = EventPlayer.new()
	player.state = state
	add_child(player)
	player.build_treasures()
	for f in state.figures:
		var v := FigureView.new()
		player.add_child(v)
		v.setup(f, "Creature" if f.side < 0 else state.side_names[f.side])
		player.views[f.id] = v
	hud.clear_log()
	player.line_logged.connect(hud.add_line)
	controller.event_emitted.connect(player.push)
	controller.event_emitted.connect(_on_event)
	player_input = BattleInput.new(controller, hud, _rig.camera, _markers)
	controller.start_game()
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
	if (_campaign_dialog != null and _campaign_dialog.visible) or (_setup != null and _setup.visible) or controller == null or not player.idle():
		_wait = 0.0
		return
	if _dirty:
		_refresh()
	var s := controller.state
	if s.over and _campaign_battle:
		_campaign_battle = false
		_campaign.settle(controller, controller.dice)
		_campaign.save()
		_open_campaign()
	if s.over or controller.awaiting_reaction() or (watch_mode and not auto_play) or (not watch_mode and s.current_side() == player_side and (s.active() == null or s.active().side >= 0)):
		_wait = 0.0
		return
	_wait += delta
	if _wait >= AUTO_DELAY:
		_wait = 0.0
		step()


func set_watch_mode(on: bool) -> void:
	if controller.state.active() != null or controller.state.group.in_progress() or not player.idle():
		hud.set_watch(watch_mode, false, false)
		return
	watch_mode = on
	controller.state.reaction_side = -2 if on else player_side
	auto_play = false
	hud.set_auto(false)
	_dirty = true


func _human_turn() -> bool:
	return (_setup == null or not _setup.visible) and not watch_mode and not controller.state.over and ((controller.state.current_side() == player_side and (controller.state.active() == null or controller.state.active().side >= 0)) or controller.awaiting_reaction())


func _on_event(event: GameEvent) -> void:
	if event.type == "terrain_changed":
		_board_view.build(controller.state.board)
	_dirty = true


func _refresh() -> void:
	_dirty = false
	_update_status()
	hud.set_watch(watch_mode, controller.state.active() == null and not controller.state.group.in_progress(), true)
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
	var score := ""
	for side in s.side_count():
		score += "  |  %s: %d" % [s.side_names[side], s.secured_count(side)]
	if s.over:
		var result := "Draw" if s.winner < 0 else "%s win" % s.side_names[s.winner]
		hud.set_status("Turn %d — %s%s" % [s.turn, result, score])
		return
	hud.set_status("Turn %d · %s · %s%s" % [s.turn, Phase.name_of(s.phase), ("Creatures" if s.current_side() < 0 else s.side_names[s.current_side()]), score])


func _add_lighting() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 35, 0)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	add_child(sun)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.1, 0.13, 0.18)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.7, 0.78, 0.9)
	e.ambient_light_energy = 0.35
	env.environment = e
	add_child(env)


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


func _begin_campaign_battle() -> void:
	if _campaign_battle or not _campaign.can_deploy():
		return
	_campaign_battle = true
	watch_mode = false
	_campaign_dialog.hide()
	new_game(0)
