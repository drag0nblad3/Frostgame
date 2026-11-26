extends Node3D
## Composition root for watching a game: loads the scenario, wires the
## controller to the views, and lets the bot play both warbands.

const SCENARIO := "treasure_skirmish"
## Pause between bot activations in Auto mode (seconds).
const AUTO_DELAY := 0.35

var controller: GameController
var player: EventPlayer
var hud: BattleHud
var auto_play := false
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
	hud.step_pressed.connect(step)
	hud.auto_toggled.connect(func(on: bool) -> void: auto_play = on)
	hud.new_game_pressed.connect(func() -> void: new_game(0))
	new_game(0)


func new_game(seed_value: int) -> void:
	if player != null:
		player.queue_free()
	var state := ScenarioLoader.load_id(SCENARIO, _figures, _terrain)
	controller = GameController.new(state, Dice.new(seed_value))
	_board_view.build(state.board)
	_rig.look_at_table(TableSpace.to_world(state.board.size * 0.5))
	player = EventPlayer.new()
	player.state = state
	add_child(player)
	player.build_treasures()
	for f in state.figures:
		var v := FigureView.new()
		player.add_child(v)
		v.setup(f, state.side_names[f.side])
		player.views[f.id] = v
	hud.clear_log()
	player.line_logged.connect(hud.add_line)
	controller.event_emitted.connect(player.push)
	controller.start_game()
	_update_status()


## Plays one bot activation for whichever side is to move.
func step() -> void:
	if controller.state.over or not player.idle():
		return
	Bot.play_activation(controller)
	_update_status()


func _process(delta: float) -> void:
	if not auto_play or controller.state.over or not player.idle():
		_wait = 0.0
		return
	_wait += delta
	if _wait >= AUTO_DELAY:
		_wait = 0.0
		step()


func _update_status() -> void:
	var s := controller.state
	var score := ""
	for side in s.side_count():
		score += "  |  %s: %d" % [s.side_names[side], s.secured_count(side)]
	if s.over:
		hud.set_status("Turn %d — game over%s" % [s.turn, score])
		return
	hud.set_status("Turn %d · %s · %s%s" % [s.turn, Phase.name_of(s.phase), s.side_names[s.current_side()], score])


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
