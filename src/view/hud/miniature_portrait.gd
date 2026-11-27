class_name MiniaturePortrait
extends SubViewportContainer
## A real 3D miniature in a self-contained studio, rendered only while visible.

var _studio: SubViewport
var _turntable: Node3D
var _model: Node3D
var _camera: Camera3D
var _key := ""
var tight_frame := false
var _model_box := AABB()


func _ready() -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_studio = SubViewport.new()
	_studio.own_world_3d = true
	_studio.render_target_update_mode = SubViewport.UPDATE_ONCE
	stretch_shrink=2 if GraphicsQuality.mode()<2 else 1
	visibility_changed.connect(_request_frame)
	resized.connect(_fit_camera)
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


func set_figure(f: Figure, color: Color, school: String = "") -> void:
	if not is_instance_valid(_turntable):
		return
	var next := "%s:%s:%s:%s:%s:%s:%s" % [f.def.id, WizardSculpt.identity(f), f.melee.id if f.melee != null else "", f.ranged.id if f.ranged != null else "", color, school if not school.is_empty() else SchoolArt.of_figure(f), f.side]
	if next == _key:
		return
	_key = next
	if is_instance_valid(_model):
		_turntable.remove_child(_model)
		_model.queue_free()
	_model = MiniatureFactory.create(f, color, school, 2 if tight_frame and GraphicsQuality.mode()>0 else GraphicsQuality.mode())
	_turntable.add_child(_model)
	_turntable.rotation.y = 0.0
	_model_box = _bounds(_model, _model.transform)
	_fit_camera()


func _fit_camera() -> void:
	if not is_instance_valid(_camera) or _model_box.size.length_squared()<=0.001:
		_request_frame()
		return
	var box := _model_box
	var center := box.get_center()
	if tight_frame:
		# Include the plinth and rotation-safe horizontal extent; frame by aspect.
		var bottom := minf(-0.25,box.position.y)
		var height := box.end.y-bottom
		var width := maxf(1.44,Vector2(box.size.x,box.size.z).length())
		var aspect := maxf(0.2,size.x/maxf(1.0,size.y))
		_camera.size=maxf(height*1.17,width*1.10/aspect)
		var target := Vector3(0,(bottom+box.end.y)*0.5,0)
		_camera.look_at_from_position(target+Vector3(1.7,0.65,-4.4),target)
	else:
		_camera.size=maxf(2.10,maxf(box.size.y*1.35,maxf(box.size.x,box.size.z)*1.8))
		var target := Vector3(0,maxf(0.38,center.y-0.06),0)
		_camera.look_at_from_position(target+Vector3(2.5,1.15,-4.4),target)
	_request_frame()


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
		_request_frame()
		accept_event()
	elif event is InputEventScreenDrag:
		_turntable.rotation.y += event.relative.x * 0.012
		_request_frame()
		accept_event()


func _request_frame() -> void:
	if is_instance_valid(_studio) and is_visible_in_tree():
		_studio.render_target_update_mode=SubViewport.UPDATE_ONCE
