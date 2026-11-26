extends SceneTree
var _frames := 0


func _initialize() -> void:
	call_deferred("_setup")


func _setup() -> void:
	root.add_child(load("res://scenes/title.tscn").instantiate())


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames < 40:
		return false
	var args := OS.get_cmdline_user_args()
	var out := args[0] if not args.is_empty() else "/tmp/title.png"
	var img := root.get_texture().get_image()
	if img == null or img.save_png(out) != OK:
		quit(1)
		return true
	print("Title captured: ",out)
	return true
