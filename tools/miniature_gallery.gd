extends SceneTree
## A renderable miniature lineup. No gameplay state is changed.
var _frames := 0
var _scene: Node3D
var _ready_to_capture := false


func _initialize() -> void:
	call_deferred("_setup")


func _setup() -> void:
	_scene = Node3D.new()
	root.add_child(_scene)
	var db := FigureDb.load_files()
	var ids := ["wizard", "apprentice", "knight", "templar", "ranger", "archer", "apothecary", "barbarian", "skeleton", "armoured_skeleton", "wraith", "genie", "ice_spider", "ice_toad", "white_gorilla", "werewolf", "snow_troll", "frost_giant", "wolf", "boar", "bear", "snow_leopard", "giant_rat", "large_construct"]
	for i in ids.size():
		var f := Figure.new(i + 1, db.get_def(ids[i]), 0 if i < 8 else -1, Vector2(2 + i % 6 * 2.2, 2 + floori(i / 6.0) * 3.1), db.unarmed())
		var v := FigureView.new()
		_scene.add_child(v)
		v.setup(f, "Gallery")
		v.face_toward(Vector3(6, 0, -12))
	var base := BoxMesh.new()
	base.size = Vector3(15, 0.25, 14)
	MiniatureFactory.mesh(_scene, base, Vector3(7, -0.14, 7), Color(0.58, 0.65, 0.73))
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -30, 0)
	sun.light_energy = 1.5
	sun.shadow_enabled = true
	_scene.add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-38, 145, 0)
	fill.light_energy = 0.6
	_scene.add_child(fill)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 15.0
	_scene.add_child(camera)
	camera.position = Vector3(7, 18, -14)
	camera.look_at(Vector3(7, 0, 6), Vector3.UP)
	camera.make_current()
	_ready_to_capture = true


func _process(_delta: float) -> bool:
	if not _ready_to_capture:
		return false
	_frames += 1
	if _frames < 40:
		return false
	var args := OS.get_cmdline_user_args()
	var out := args[0] if not args.is_empty() else "/tmp/miniatures.png"
	var img := root.get_texture().get_image()
	if img == null or img.save_png(out) != OK:
		quit(1)
		return true
	print("Gallery captured: ", out)
	return true
