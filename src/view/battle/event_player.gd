class_name EventPlayer
extends Node3D
## Plays GameEvents one after another as simple animations. Reads state for
## names and health; never changes it.

signal line_logged(text: String)
signal notice(text: String)
signal roll_resolved(text: String)
const NOTICES := ["hut_discovered", "disc_transport", "disc_stay", "well_drink", "worm_emerges", "break_ice", "column_fight", "column_opened", "genie_released", "genie_flee", "genie_escaped", "null_field", "tower_entered"]

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
		if e.type in NOTICES:
			notice.emit(line)
		else:
			line_logged.emit(line)
	var result := RollSummary.describe(state, e)
	if not result.is_empty():
		roll_resolved.emit(result)
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
		"layered_move":
			_animate_layered_move(_view(d["id"]),d["path"])
		"move", "push_back", "force_combat":
			_animate_move(_view(d["id"]), d["path"])
		"terrain_fall":
			var f := state.figure(d["id"])
			_view(f.id).position = TableSpace.to_world(f.pos, f.elevation)
		"allegiance", "spell_effect", "spell_expired", "weapon_selected", "weapon_destroyed", "poison", "null_field", "shield_absorb":
			_view(d["id"]).refresh(state.figure(d["id"]))
		"cast_result":
			if views.has(d["id"]):
				var caster := _view(d["id"])
				var color := SpellVisuals.color_for(str(d["spell"]),state)
				if d["success"]:
					SpellVisuals.sigil(self,caster.position+Vector3.UP*0.16,color,1.25)
				else:
					BattleEffects.pulse(self,caster.position+Vector3.UP*0.15,Color(0.90,0.38,0.36),1.1)
				var pose_tween := create_tween()
				pose_tween.tween_method(caster.cast_pose,0.0,1.0,0.13)
				pose_tween.tween_method(caster.cast_pose,1.0,0.0,0.22)
				_wait_for(pose_tween)
		"disc_transport":
			BattleEffects.pulse(self, _view(d["id"]).position + Vector3.UP * 0.15, Color(1.0,0.78,0.32), 1.6)
		"heal":
			var healed := _view(d["id"])
			healed.refresh(state.figure(d["id"]))
			BattleEffects.pulse(self, healed.position + Vector3.UP * 0.15, Color(0.40,0.95,0.59))
			_float_text(healed, "+%d" % d["amount"], Color(0.45, 1.0, 0.63))
		"shoot", "spell_shot":
			_animate_shot(_view(d["id"]), _view(d["target"]), e.type == "spell_shot",str(d.get("spell","")),d.get("origin",null))
		"fight":
			var a := _view(d["id"])
			var b := _view(d["target"])
			if int(d["winner"]) == int(d["target"]):
				_animate_lunge(b, a)
			else:
				_animate_lunge(a, b)
		"damage":
			var v := _view(d["id"])
			v.refresh(state.figure(d["id"]))
			_float_text(v, "-%d" % d["amount"])
		"out_of_action":
			_view(d["id"]).take_out()
		"treasure_pickup":
			var token: MeshInstance3D = treasure_views[d["treasure"]]
			token.reparent(_view(d["id"]), false)
			token.position = Vector3(-0.48 if state.figure(d["id"]).second_treasure_id >= 0 else 0.48, 0.65, 0)
			_view(d["id"]).refresh(state.figure(d["id"]))
			BattleEffects.pulse(self, _view(d["id"]).position + Vector3.UP * 0.13, Color(1.0,0.74,0.28))
		"treasure_drop":
			var token: MeshInstance3D = treasure_views[d["treasure"]]
			token.reparent(self, false)
			token.position = TableSpace.to_world(d["at"], 0.25 + state.board.height_at(d["at"]))
			_view(d["id"]).refresh(state.figure(d["id"]))
		"treasure_moved":
			var token: MeshInstance3D = treasure_views[d["treasure"]]
			token.position = TableSpace.to_world(d["at"], 0.25 + state.board.height_at(d["at"]))
		"column_opened":
			if treasure_views.has(d["treasure"]):
				var token: MeshInstance3D = treasure_views[d["treasure"]]
				token.visible = true
				token.material_override = BoardView._mat(Color(1.0, 0.73, 0.15), 0.3)
		"break_ice":
			if d["success"] and treasure_views.has(0):
				treasure_views[0].material_override = BoardView._mat(Color(1.0, 0.73, 0.15), 0.3)
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


func _animate_layered_move(v: FigureView,path: PackedVector3Array) -> void:
	if path.size()<2:
		return
	v.begin_move()
	var t := create_tween()
	for i in range(1,path.size()):
		var destination := path[i]
		var duration := maxf(0.01,path[i-1].distance_to(destination)*0.06)
		t.tween_callback(v.face_toward.bind(destination))
		t.tween_property(v,"position",destination,duration)
	t.tween_callback(v.end_move)
	_wait_for(t)


func _animate_move(v: FigureView, path: PackedVector2Array) -> void:
	if path.size() < 2:
		return
	v.begin_move()
	var t := create_tween()
	for i in range(1, path.size()):
		var destination := TableSpace.to_world(path[i], state.board.height_at(path[i]))
		var start := TableSpace.to_world(path[i - 1], state.board.height_at(path[i - 1]))
		var duration := maxf(0.01, start.distance_to(destination) * 0.06)
		t.tween_callback(v.face_toward.bind(destination))
		t.tween_property(v, "position", destination, duration)
	t.tween_callback(v.end_move)
	_wait_for(t)


func _animate_shot(from: FigureView, to: FigureView, magic: bool = false, spell: String = "", origin: Variant = null) -> void:
	from.face_toward(to.position)
	var color := SpellVisuals.color_for(spell,state) if magic else Color(0.92,0.78,0.50)
	var bolt := SpellVisuals.projectile(spell,magic,color)
	add_child(bolt)
	var start := from.position + Vector3.UP*from.body_height()
	if origin is Vector2:
		start = TableSpace.to_world(origin,state.board.height_at(origin)+1.0)
	var destination := to.position + Vector3.UP*to.body_height()
	bolt.position = start
	if start.distance_squared_to(destination)>0.001:
		bolt.look_at(destination)
	bolt.hide()
	var t := create_tween()
	t.tween_method(from.cast_pose if magic else from.shot_pose, 0.0, 0.75, 0.14)
	t.tween_callback(bolt.show)
	t.tween_property(bolt, "position", destination, maxf(0.10,start.distance_to(destination)*0.035))
	t.parallel().tween_method(from.cast_pose if magic else from.shot_pose, 0.75, 0.0, 0.15)
	t.tween_callback(bolt.queue_free)
	t.tween_callback(BattleEffects.burst.bind(self,destination,color))
	if spell == "elemental_ball":
		t.tween_callback(BattleEffects.pulse.bind(self,to.position+Vector3.UP*0.15,color,1.7))
	_wait_for(t)


func _animate_lunge(a: FigureView, b: FigureView) -> void:
	a.face_toward(b.position)
	b.face_toward(a.position)
	var home := a.position
	var toward := home.lerp(b.position, 0.35)
	var t := create_tween()
	t.tween_method(a.attack_pose, 0.0, -0.45, 0.12)
	t.tween_property(a, "position", toward, 0.13)
	t.parallel().tween_method(a.attack_pose, -0.45, 1.0, 0.13)
	t.tween_callback(BattleEffects.burst.bind(self, toward.lerp(b.position, 0.5) + Vector3.UP * 0.85, Color(1.0, 0.78, 0.38)))
	t.tween_method(b.recoil_pose, 0.0, 1.0, 0.10)
	t.parallel().tween_property(a, "position", home, 0.20)
	t.parallel().tween_method(a.attack_pose, 1.0, 0.0, 0.20)
	t.tween_method(b.recoil_pose, 1.0, 0.0, 0.14)
	_wait_for(t)


func _float_text(v: FigureView, text: String, color: Color = Color(1, 0.35, 0.3)) -> void:
	var l := Label3D.new()
	l.text = text
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.font_size = 64
	l.pixel_size = 0.01
	l.outline_size = 12
	l.modulate = color
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
		marker.material_override = BoardView._mat(Color(0.42, 0.83, 1.0) if token.frozen else Color(1.0, 0.73, 0.15), 0.3)
		add_child(marker)
		TerrainDressing.chest(marker)
		marker.position = TableSpace.to_world(token.pos, 0.25 + state.board.height_at(token.pos))
		treasure_views[token.id] = marker
		if not token.unresolved() or (state.scenario_special == "complex_temple" and token.frozen):
			marker.visible = false
		elif token.carrier_id >= 0 and views.has(token.carrier_id):
			var carrier := state.figure(token.carrier_id)
			marker.reparent(views[token.carrier_id], false)
			marker.position = Vector3(-0.48 if carrier.second_treasure_id == token.id else 0.48, 0.65, 0)
