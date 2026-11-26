class_name EventPlayer
extends Node3D
## Plays GameEvents one after another as simple animations. Reads state for
## names and health; never changes it.

signal line_logged(text: String)

## Animation speed multiplier (higher is faster).
var speed := 1.0
var state: GameState
var views := {}
var treasure_views := {}
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
		"creature_spawn":
			var f := state.figure(d["id"])
			var v := FigureView.new()
			add_child(v)
			v.setup(f, "Creature" if f.side < 0 else state.side_names[f.side])
			views[f.id] = v
		"move", "push_back", "force_combat":
			_animate_move(_view(d["id"]), d["path"])
		"terrain_fall":
			var f := state.figure(d["id"])
			_view(f.id).position = TableSpace.to_world(f.pos, f.elevation)
		"allegiance", "heal", "spell_effect", "spell_expired":
			_view(d["id"]).refresh(state.figure(d["id"]))
		"shoot", "spell_shot":
			_animate_shot(_view(d["id"]), _view(d["target"]))
		"fight":
			_animate_lunge(_view(d["id"]), _view(d["target"]))
		"damage":
			var v := _view(d["id"])
			v.refresh(state.figure(d["id"]))
			_float_text(v, "-%d" % d["amount"])
		"out_of_action":
			_view(d["id"]).take_out()
		"treasure_pickup":
			var token: MeshInstance3D = treasure_views[d["treasure"]]
			token.reparent(_view(d["id"]), false)
			token.position = Vector3(0.48, 0.65, 0)
		"treasure_drop":
			var token: MeshInstance3D = treasure_views[d["treasure"]]
			token.reparent(self, false)
			token.position = TableSpace.to_world(d["at"], 0.25 + state.board.height_at(d["at"]))
		"treasure_secured", "treasure_lost":
			var token: MeshInstance3D = treasure_views[d["treasure"]]
			token.visible = false
		"exit":
			_view(d["id"]).visible = false


func _view(id: int) -> FigureView:
	return views[id]


func _wait_for(t: Tween) -> void:
	_busy = true
	t.set_speed_scale(speed)
	t.finished.connect(func() -> void: _busy = false)


func _animate_move(v: FigureView, path: PackedVector2Array) -> void:
	var t := create_tween()
	for i in range(1, path.size()):
		var destination := TableSpace.to_world(path[i], state.board.height_at(path[i]))
		var start := TableSpace.to_world(path[i - 1], state.board.height_at(path[i - 1]))
		var duration := maxf(0.01, start.distance_to(destination) * 0.06)
		t.tween_property(v, "position", destination, duration)
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


func build_treasures() -> void:
	for token in state.treasures:
		var marker := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.6, 0.5, 0.45)
		marker.mesh = box
		marker.material_override = BoardView._mat(Color(1.0, 0.73, 0.15), 0.3)
		add_child(marker)
		marker.position = TableSpace.to_world(token.pos, 0.25 + state.board.height_at(token.pos))
		treasure_views[token.id] = marker
