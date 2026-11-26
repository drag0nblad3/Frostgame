class_name CameraRig
extends Node3D
## Orbit camera around a point on the table.
## Mouse: left-drag orbit, right-drag pan, wheel zoom.
## Touch: one-finger drag orbit, two-finger drag pan, pinch zoom.

var yaw := PI
var pitch := deg_to_rad(55.0)
var distance := 34.0
var min_distance := 8.0
var max_distance := 80.0
var camera: Camera3D
var _touches := {}
var _pinch_start := 0.0
var _pinch_distance := 0.0


func _ready() -> void:
	camera = Camera3D.new()
	camera.fov = 50.0
	add_child(camera)
	_apply()


func look_at_table(center: Vector3) -> void:
	position = center
	_apply()


func _apply() -> void:
	if camera == null:
		return
	pitch = clampf(pitch, deg_to_rad(15.0), deg_to_rad(88.0))
	distance = clampf(distance, min_distance, max_distance)
	var offset := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * distance
	camera.position = offset
	camera.look_at(global_position, Vector3.UP)


func _pan(delta: Vector2) -> void:
	var right := Vector3(cos(yaw), 0, -sin(yaw))
	var fwd := Vector3(sin(yaw), 0, cos(yaw))
	position -= (right * delta.x + fwd * delta.y) * distance * 0.002
	_apply()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			yaw -= event.relative.x * 0.008
			pitch += event.relative.y * 0.006
			_apply()
		elif event.button_mask & MOUSE_BUTTON_MASK_RIGHT:
			_pan(event.relative)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance *= 0.9
			_apply()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance *= 1.1
			_apply()
	elif event is InputEventScreenTouch:
		if event.pressed:
			_touches[event.index] = event.position
		else:
			_touches.erase(event.index)
		if _touches.size() == 2:
			_pinch_start = _touch_span()
			_pinch_distance = distance
	elif event is InputEventScreenDrag:
		_touches[event.index] = event.position
		if _touches.size() == 1:
			yaw -= event.relative.x * 0.008
			pitch += event.relative.y * 0.006
			_apply()
		elif _touches.size() == 2:
			_pan(event.relative * 0.5)
			var span := _touch_span()
			if span > 1.0 and _pinch_start > 1.0:
				distance = _pinch_distance * _pinch_start / span
				_apply()


func _touch_span() -> float:
	var pts: Array = _touches.values()
	return (pts[0] as Vector2).distance_to(pts[1])
