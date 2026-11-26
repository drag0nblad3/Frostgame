class_name EventPlayer
extends Node3D
## Plays GameEvents one after another as simple animations. Reads state for
## names and health; never changes it.

signal line_logged(text: String)

## Animation speed multiplier (higher is faster).
var speed := 1.0
var state: GameState
var views := {}
var _queue: Array[GameEvent] = []
var _busy := false


func push(e: GameEvent) -> void:
	_queue.append(e)


func idle() -> bool:
	return not _busy and _queue.is_empty()


func _process(_delta: float) -> void:
	while not _busy and not _queue.is_empty():
		_play(_queue.pop_front())


func _play(e: GameEvent) -> void:
	var line := Explainer.text(state, e)
	if line != "":
		line_logged.emit(line)
	var d := e.data
	match e.type:
		"activate":
			_view(d["id"]).set_active(true)
		"end_activation":
			_view(d["id"]).set_active(false)
		"move":
			_animate_move(_view(d["id"]), d["path"])
		"shoot":
			_animate_shot(_view(d["id"]), _view(d["target"]))
		"fight":
			_animate_lunge(_view(d["id"]), _view(d["target"]))
		"damage":
			var v := _view(d["id"])
			v.refresh(state.figure(d["id"]))
			_float_text(v, "-%d" % d["amount"])
		"out_of_action":
			_view(d["id"]).take_out()


func _view(id: int) -> FigureView:
	return views[id]


func _wait_for(t: Tween) -> void:
	_busy = true
	t.set_speed_scale(speed)
	t.finished.connect(func() -> void: _busy = false)


func _animate_move(v: FigureView, path: PackedVector2Array) -> void:
	var t := create_tween()
	for i in range(1, path.size()):
		var step := path[i - 1].distance_to(path[i])
		t.tween_property(v, "position", TableSpace.to_world(path[i]), step * 0.06)
	_wait_for(t)


func _animate_shot(from: FigureView, to: FigureView) -> void:
	var bolt := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = 0.15
	s.height = 0.3
	bolt.mesh = s
	bolt.material_override = BoardView._mat(Color(1, 0.9, 0.5), 0.2)
	add_child(bolt)
	var up := Vector3(0, 1.1, 0)
	bolt.position = from.position + up
	var t := create_tween()
	t.tween_property(bolt, "position", to.position + up, from.position.distance_to(to.position) * 0.03)
	t.tween_callback(bolt.queue_free)
	_wait_for(t)


func _animate_lunge(a: FigureView, b: FigureView) -> void:
	var home := a.position
	var toward := home.lerp(b.position, 0.35)
	var t := create_tween()
	t.tween_property(a, "position", toward, 0.12)
	t.tween_property(a, "position", home, 0.18)
	_wait_for(t)


func _float_text(v: FigureView, text: String) -> void:
	var l := Label3D.new()
	l.text = text
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.font_size = 64
	l.pixel_size = 0.01
	l.outline_size = 12
	l.modulate = Color(1, 0.35, 0.3)
	add_child(l)
	l.position = v.position + Vector3(0, v.body_height() + 1.5, 0)
	var t := create_tween()
	t.tween_property(l, "position:y", l.position.y + 1.5, 0.7)
	t.parallel().tween_property(l, "modulate:a", 0.0, 0.7)
	t.tween_callback(l.queue_free)
	_wait_for(t)
