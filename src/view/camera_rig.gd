class_name CameraRig
extends Node3D
## Orbit camera around a point on the table.
## Mouse: left-drag orbit, right-drag pan, wheel zoom.
## Touch: one-finger drag orbit, two-finger drag pan, pinch zoom.

signal tapped(at: Vector2)

const TAP_SLOP := 12.0
var _mouse_down := false
var _mouse_start := Vector2.ZERO
var _mouse_dragged := false
var _touch_start := Vector2.ZERO
var _touch_dragged := false

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
	# Native touch is handled below; ignore its emulated mouse events here.
	if event is InputEventMouse and event.device == -1:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_mouse_down = true
				_mouse_start = event.position
				_mouse_dragged = false
			else:
				if _mouse_down and not _mouse_dragged and event.position.distance_to(_mouse_start) <= TAP_SLOP:
					tapped.emit(event.position)
				_mouse_down = false
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance *= 0.9
			_apply()
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance *= 1.1
			_apply()
	elif event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			if _mouse_down and event.position.distance_to(_mouse_start) > TAP_SLOP:
				_mouse_dragged = true
			if _mouse_dragged:
				yaw -= event.relative.x * 0.008
				pitch += event.relative.y * 0.006
				_apply()
		elif event.button_mask & MOUSE_BUTTON_MASK_RIGHT:
			_pan(event.relative)
	elif event is InputEventScreenTouch:
		if event.pressed:
			if _touches.is_empty():
				_touch_start = event.position
				_touch_dragged = false
			else:
				_touch_dragged = true
			_touches[event.index] = event.position
		else:
			if _touches.has(event.index) and _touches.size() == 1 and not _touch_dragged and event.position.distance_to(_touch_start) <= TAP_SLOP and not event.canceled:
				tapped.emit(event.position)
			_touches.erase(event.index)
		if _touches.size() == 2:
			_pinch_start = _touch_span()
			_pinch_distance = distance
	elif event is InputEventScreenDrag:
		if not _touches.has(event.index):
			return
		_touches[event.index] = event.position
		if _touches.size() == 1:
			if event.position.distance_to(_touch_start) > TAP_SLOP:
				_touch_dragged = true
			if _touch_dragged:
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
