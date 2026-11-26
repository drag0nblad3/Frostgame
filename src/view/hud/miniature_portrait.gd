class_name MiniaturePortrait
extends SubViewportContainer
## A real 3D miniature in a self-contained studio, rendered only while visible.

var _studio: SubViewport
var _turntable: Node3D
var _model: Node3D
var _camera: Camera3D
var _key := ""


func _ready() -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_studio = SubViewport.new()
	_studio.own_world_3d = true
	_studio.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	_studio.size = Vector2i(300, 300)
	add_child(_studio)
	var room := Node3D.new()
	_studio.add_child(room)
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.095, 0.14, 0.18)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.68, 0.78, 0.88)
	environment.ambient_light_energy = 0.52
	world.environment = environment
	room.add_child(world)
	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-42, -28, 0)
	key_light.light_energy = 1.30
	key_light.light_color = Color(1.0, 0.89, 0.69)
	room.add_child(key_light)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-38, 135, 0)
	fill.light_color = Color(0.55, 0.77, 1.0)
	fill.light_energy = 0.7
	room.add_child(fill)
	_turntable = Node3D.new()
	room.add_child(_turntable)
	var plinth := MiniatureFactory.cylinder(_turntable, Vector3(0, -0.14, 0), 0.64, 0.71, 0.28, Color(0.18, 0.23, 0.27))
	WeaponSculpt.metal(MiniatureFactory.cylinder(_turntable, Vector3(0, -0.22, 0), 0.70, 0.70, 0.055, Color(0.68, 0.53, 0.30)))
	_camera = Camera3D.new()
	_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	_camera.size = 2.9
	room.add_child(_camera)
	_camera.position = Vector3(2.5, 1.8, -4.4)
	_camera.look_at_from_position(_camera.position, Vector3(0, 0.85, 0))
	_camera.make_current()
	gui_input.connect(_drag)
	set_process(false)


func set_figure(f: Figure, color: Color) -> void:
	if not is_instance_valid(_turntable):
		return
	var next := "%s:%s:%s:%s:%s" % [f.def.id, f.id, f.melee.id if f.melee != null else "", f.ranged.id if f.ranged != null else "", color]
	if next == _key:
		return
	_key = next
	if is_instance_valid(_model):
		_turntable.remove_child(_model)
		_model.queue_free()
	_model = MiniatureFactory.create(f, color)
	_turntable.add_child(_model)
	_turntable.rotation.y = 0.0
	var box := _bounds(_model, _model.transform)
	if box.size.length_squared() > 0.001:
		var height := box.size.y
		var center := box.get_center()
		_camera.size = maxf(2.10, maxf(height * 1.35, maxf(box.size.x, box.size.z) * 1.8))
		var target := Vector3(0, maxf(0.38, center.y - 0.06), 0)
		_camera.look_at_from_position(target + Vector3(2.5, 1.15, -4.4), target)


func _bounds(node: Node3D, transform: Transform3D) -> AABB:
	var out := AABB()
	var has_mesh := false
	if node is MeshInstance3D and node.mesh != null:
		out = transform * node.mesh.get_aabb()
		has_mesh = true
	for child in node.get_children():
		if child is Node3D:
			var child_box := _bounds(child, transform * child.transform)
			if child_box.size.length_squared() > 0.00001:
				out = out.merge(child_box) if has_mesh else child_box
				has_mesh = true
	return out


func _drag(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		_turntable.rotation.y += event.relative.x * 0.012
		accept_event()
	elif event is InputEventScreenDrag:
		_turntable.rotation.y += event.relative.x * 0.012
		accept_event()
