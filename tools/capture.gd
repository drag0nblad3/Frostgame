extends SceneTree
## Renders the battle scene to a PNG after some bot activations, for visual checks:
##   xvfb-run -a godot --rendering-method gl_compatibility --resolution 1280x720 \
##     -s tools/capture.gd -- /tmp/shot.png [activations]

var _scene: Node
var _out := "/tmp/frostgame.png"
var _left := 12
var _frames := 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	if args.size() > 1:
		_left = int(args[1])
	_scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(_scene)


func _process(_delta: float) -> bool:
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
	img.save_png(_out)
	print("capture saved ", _out)
	return true
