extends SceneTree
## Renders the battle scene to a PNG after some bot activations, for visual checks:
##   xvfb-run -a godot --rendering-method gl_compatibility --resolution 1280x720 \
##     -s tools/capture.gd -- /tmp/shot.png [activations]

var _scene: Node
var _out := "/tmp/frostgame.png"
var _left := 12
var _frames := 0
var _ready_to_capture := false
var _scenario := "treasure_skirmish"


func _initialize() -> void:
	call_deferred("_setup")


func _setup() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	if args.size() > 1:
		_left = int(args[1])
	_scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(_scene)
	_scene.watch_mode = true
	if args.size() > 2:
		_scenario = args[2]
	if _scenario.begins_with("red_king_"):
		_scene._figures=FigureDb.load_files(FigureDb.FIGURES,FigureDb.WEAPONS,ContentProfile.new(["red_king"]))
		_scene._roster={}
	_scene._scenario_id = _scenario
	_scene.new_game(17)
	if _scene._active_scenario_id != _scenario or _scene.controller == null:
		printerr("Capture scenario failed: ", _scenario)
		quit(1)
		return
	var expected: Dictionary = JsonFile.read(ScenarioLoader.DIR + _scenario + ".json")
	if _scene.controller.state.board.id != expected.get("board", ""):
		printerr("Wrong board for capture: ", _scene.controller.state.board.id)
		quit(1)
		return
	if args.size()>3:
		if not RealityCracks.apply(_scene.controller,int(args[3])):
			printerr("Unable to apply preview reality crack: ",args[3])
			quit(1)
			return
	_ready_to_capture = true


func _process(_delta: float) -> bool:
	if not _ready_to_capture:
		return false
	_frames += 1
	if _frames < 3:
		return false
	var player: EventPlayer = _scene.player
	player.speed = 20.0
	if not player.idle():
		return false
	if _left > 0 and not _scene.controller.state.over:
		_scene.step()
		_left -= 1
		return false
	if _frames < 40:
		return false
	var img := root.get_viewport().get_texture().get_image()
	if img == null or img.save_png(_out) != OK:
		printerr("Failed to save capture: ", _out)
		quit(1)
		return true
	print("capture saved ", _out, " scenario=", _scenario, " board=", _scene.controller.state.board.id)
	return true
