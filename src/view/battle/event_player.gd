class_name EventPlayer
extends Node3D
## Plays GameEvents one after another as simple animations. Reads state for
## names and health; never changes it.

signal line_logged(text: String)
signal notice(text: String)
signal roll_resolved(text: String)
signal outcome(text: String)
const NOTICES := ["hut_discovered", "disc_transport", "disc_stay", "well_drink", "worm_emerges", "break_ice", "column_fight", "column_opened", "genie_released", "genie_flee", "genie_escaped", "null_field", "tower_entered"]

## Animation speed multiplier (higher is faster).
var speed := 0.8
const RESULT_HOLD := 0.8
const NOTICE_HOLD := 1.3
const DAMAGE_HOLD := 1.7
var state: GameState
var views := {}
var treasure_views := {}
var _queue: Array[GameEvent] = []
var _busy := false
## A bot is thinking on another thread; callers must wait as if animating.
var thinking := false


func push(e: GameEvent) -> void:
	_queue.append(e)


func idle() -> bool:
	return not _busy and not thinking and _queue.is_empty()


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
	if not line.is_empty() and e.type in ["damage","heal","out_of_action","spell_effect","spell_expired","poison","shield_absorb","weapon_destroyed","treasure_pickup","treasure_secured","treasure_lost","terrain_fall","ring_switch","creature_transformed"]:
		outcome.emit(line)
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
		"ring_switch":
			var v := _view(d["id"])
			v.refresh(state.figure(d["id"]))
			BattleEffects.pulse(self,v.position+Vector3.UP*0.15,Color(0.32,0.85,0.76))
		"creature_transformed":
			var creature := _view(d["id"])
			creature.refresh(state.figure(d["id"]))
			BattleEffects.burst(self,creature.position+Vector3.UP,Color(1.0,0.4,0.12))
		"forced_relocation":
			var v := _view(d["id"])
			BattleEffects.pulse(self,v.position+Vector3.UP*0.15,Color(0.73,0.42,0.95))
			v.position=TableSpace.to_world(d["at"],d["height"])
			BattleEffects.pulse(self,v.position+Vector3.UP*0.15,Color(0.73,0.42,0.95))
		"layered_move":
			_animate_layered_move(_view(d["id"]),d["path"])
		"move", "push_back", "force_combat":
			_animate_move(_view(d["id"]), d["path"])
		"terrain_fall":
			var f := state.figure(d["id"])
			_view(f.id).position = TableSpace.to_world(f.pos, f.elevation)
		"allegiance", "spell_effect", "spell_expired", "weapon_selected", "weapon_destroyed", "poison", "null_field", "shield_absorb":
			var affected := _view(d["id"])
			affected.refresh(state.figure(d["id"]))
			if e.type in ["spell_effect","spell_expired","poison","null_field","shield_absorb","weapon_destroyed"]:
				var effect := str(d.get("spell",e.type)).replace("_"," ").capitalize()
				if e.type=="spell_expired":
					effect+=" ends"
				_float_text(affected,effect,Color("8ed8ef"))
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
				pose_tween.tween_interval(0.6)
				_wait_for(pose_tween)
		"disc_transport":
			BattleEffects.pulse(self, _view(d["id"]).position + Vector3.UP * 0.15, Color(1.0,0.78,0.32), 1.6)
		"heal":
			var healed := _view(d["id"])
			healed.refresh(state.figure(d["id"]))
			BattleEffects.restore(self, healed.position + Vector3.UP * 0.15)
			_float_text(healed, "+%d" % d["amount"], Color(0.45, 1.0, 0.63))
		"shoot", "spell_shot":
			_animate_shot(_view(d["id"]), _view(d["target"]), e.type == "spell_shot",str(d.get("spell","")),d.get("origin",null),int(d.get("dmg",int(d.get("attack",1))>int(d.get("defence",0))))>0)
		"fight":
			var a := _view(d["id"])
			var b := _view(d["target"])
			if int(d["winner"]) == int(d["target"]):
				_animate_lunge(b, a)
			else:
				_animate_lunge(a, b,int(d["winner"])<0)
		"damage":
			var v := _view(d["id"])
			v.refresh(state.figure(d["id"]))
			_float_text(v, "-%d" % d["amount"])
		"out_of_action":
			var fallen := _view(d["id"])
			var defeat := fallen.take_out()
			defeat.tween_interval(0.7)
			_wait_for(defeat)
		"pylon_destroyed":
			var marker: MeshInstance3D=treasure_views[d["treasure"]]
			marker.position=TableSpace.to_world(d["at"],state.board.height_at(d["at"])+0.25)
			marker.show()
		"ryce_unconscious":
			var marker: MeshInstance3D=treasure_views[d["treasure"]]
			marker.position=TableSpace.to_world(d["at"],state.board.height_at(d["at"])+0.25)
			marker.show()
		"stand_investigated":
			var marker: MeshInstance3D=treasure_views[d["treasure"]]
			if int(d["gold"])==0:
				marker.hide()
			else:
				# Retain the node identity: later pickup events reparent it.
				for child in marker.get_children():
					marker.remove_child(child)
					child.queue_free()
				var chest := BoxMesh.new()
				chest.size=Vector3(0.6,0.5,0.45)
				marker.mesh=chest
				marker.material_override=BoardView._mat(Color(1.0,0.73,0.15),0.3)
				TerrainDressing.chest(marker)
		"treasure_pickup":
			var token: MeshInstance3D = treasure_views[d["treasure"]]
			token.reparent(_view(d["id"]), false)
			token.position = Vector3(-0.48 if state.figure(d["id"]).second_treasure_id >= 0 else 0.48, 0.65, 0)
			_view(d["id"]).refresh(state.figure(d["id"]))
			BattleEffects.pulse(self, _view(d["id"]).position + Vector3.UP * 0.13, Color(1.0,0.74,0.28))
		"treasure_drop":
			var token: MeshInstance3D = treasure_views[d["treasure"]]
			token.reparent(self, false)
			token.position = TableSpace.to_world(d["at"], 0.25 + float(d.get("height",state.board.height_at(d["at"]))))
			_view(d["id"]).refresh(state.figure(d["id"]))
		"treasure_moved":
			var token: MeshInstance3D = treasure_views[d["treasure"]]
			token.position = TableSpace.to_world(d["at"], 0.25 + float(d.get("height",state.board.height_at(d["at"]))))
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
	# Don’t let non-animated results flash by in a single process tick.
	if not _busy and not line.is_empty() and e.type not in ["activate","end_activation","move","layered_move","push_back","force_combat"]:
		_hold(NOTICE_HOLD if e.type in NOTICES or e.type.begins_with("reality_") else RESULT_HOLD)


func _view(id: int) -> FigureView:
	return views[id]


func _hold(seconds: float) -> void:
	var t := create_tween()
	t.tween_interval(seconds)
	_wait_for(t)


func _wait_for(t: Tween) -> void:
	_busy = true
	t.set_speed_scale(speed)
	t.finished.connect(func() -> void: _busy = false)


func _animate_layered_move(v: FigureView,path: PackedVector3Array) -> void:
	if path.size()<2:
		return
	var distance := 0.0
	for i in range(1,path.size()):
		distance+=path[i-1].distance_to(path[i])
	v.begin_move(distance)
	var t := create_tween()
	for i in range(1,path.size()):
		var destination := path[i]
		var duration := maxf(0.01,path[i-1].distance_to(destination)*0.115)
		t.tween_callback(v.face_toward.bind(destination))
		t.tween_property(v,"position",destination,duration)
	t.tween_callback(v.end_move)
	_wait_for(t)


func _animate_move(v: FigureView, path: PackedVector2Array) -> void:
	if path.size() < 2:
		return
	var distance := 0.0
	for i in range(1,path.size()):
		distance+=path[i-1].distance_to(path[i])
	v.begin_move(distance)
	var t := create_tween()
	for i in range(1, path.size()):
		var destination := TableSpace.to_world(path[i], state.board.height_at(path[i]))
		var start := TableSpace.to_world(path[i - 1], state.board.height_at(path[i - 1]))
		var duration := maxf(0.01, start.distance_to(destination) * 0.115)
		t.tween_callback(v.face_toward.bind(destination))
		t.tween_property(v, "position", destination, duration)
	t.tween_callback(v.end_move)
	_wait_for(t)


func _animate_shot(from: FigureView, to: FigureView, magic: bool = false, spell: String = "", origin: Variant = null, damaging: bool = true) -> void:
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
	t.tween_method(from.cast_pose if magic else from.shot_pose, 0.0, 0.88, 0.20).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_callback(bolt.show)
	t.tween_property(bolt, "position", destination, maxf(0.10,start.distance_to(destination)*0.035))
	t.parallel().tween_method(from.cast_pose if magic else from.shot_pose, 0.88, 0.0, 0.23).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_callback(bolt.queue_free)
	t.tween_callback(BattleEffects.impact.bind(self,destination,color,damaging,magic))
	if spell == "elemental_ball" and damaging:
		t.tween_callback(BattleEffects.pulse.bind(self,to.position+Vector3.UP*0.15,color,1.7))
	t.tween_interval(0.5)
	_wait_for(t)


func _animate_lunge(a: FigureView, b: FigureView,tied: bool=false) -> void:
	a.face_toward(b.position)
	b.face_toward(a.position)
	var home := a.position
	var toward := home.lerp(b.position, 0.35)
	var t := create_tween()
	t.tween_method(a.attack_pose, 0.0, -0.45, 0.17).set_trans(Tween.TRANS_SINE)
	t.parallel().tween_method(b.guard_pose,0.0,1.0,0.17)
	t.tween_property(a, "position", toward, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.parallel().tween_method(a.attack_pose, -0.45, 1.0, 0.16)
	t.tween_callback(BattleEffects.clash.bind(self,toward.lerp(b.position,0.5)+Vector3.UP*0.85,b.position-home,tied))
	t.tween_method(b.guard_pose,1.0,0.0,0.06)
	t.tween_method(b.recoil_pose, 0.0, 0.35 if tied else 1.0, 0.12)
	t.parallel().tween_property(a, "position", home, 0.20)
	t.parallel().tween_method(a.attack_pose, 1.0, 0.0, 0.20)
	t.tween_method(b.recoil_pose, 0.35 if tied else 1.0, 0.0, 0.18)
	t.tween_interval(0.5)
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
	t.tween_interval(0.45)
	t.tween_property(l,"position:y",l.position.y+1.2,DAMAGE_HOLD-0.45)
	t.parallel().tween_property(l,"modulate:a",0.0,0.45).set_delay(DAMAGE_HOLD-0.9)
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
		if token.investigation:
			_build_stand(marker)
		elif RedKingMadMan.rescue(state,token):
			_build_rescue(marker)
		else:
			TerrainDressing.chest(marker)
		if RedKingRingworld.active(state):
			var label := Label3D.new()
			label.text="IN" if token.ring_side==1 else "OUT"
			label.modulate=Color(0.35,0.95,0.82) if token.ring_side==1 else Color(1.0,0.75,0.4)
			label.font_size=50
			label.pixel_size=0.01
			label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
			label.position.y=0.6
			marker.add_child(label)
		var height := state.board.height_at(token.pos)
		if not token.surface_id.is_empty():
			var layout := FloorLayout.from_dict(state.board.floor_layout)
			var index := layout.index_of(token.surface_id)
			if index>=0:
				height=layout.surfaces[index].height_at(token.pos)
		marker.position = TableSpace.to_world(token.pos, 0.25 + height)
		treasure_views[token.id] = marker
		if not token.unresolved() or (state.scenario_special == "complex_temple" and token.frozen):
			marker.visible = false
		elif token.carrier_id >= 0 and views.has(token.carrier_id):
			var carrier := state.figure(token.carrier_id)
			marker.reparent(views[token.carrier_id], false)
			marker.position = Vector3(-0.48 if carrier.second_treasure_id == token.id else 0.48, 0.65, 0)


func _build_stand(marker: MeshInstance3D) -> void:
	# Three timber legs and a crimson hanging offering; same pick radius as a token.
	var base := CylinderMesh.new()
	base.top_radius=0.26
	base.bottom_radius=0.32
	base.height=0.12
	base.radial_segments=12
	marker.mesh=base
	marker.material_override=BoardView._mat(Color(0.44,0.25,0.15),0.9)
	for i in 3:
		var leg := MeshInstance3D.new()
		var shaft := CylinderMesh.new()
		shaft.top_radius=0.045
		shaft.bottom_radius=0.065
		shaft.height=0.95
		shaft.radial_segments=6
		leg.mesh=shaft
		var direction := Vector3.RIGHT.rotated(Vector3.UP,TAU*i/3.0)
		leg.position=direction*0.14+Vector3.UP*0.32
		leg.quaternion=Quaternion(Vector3.UP,(Vector3.UP*0.9-direction*0.28).normalized())
		leg.material_override=marker.material_override
		marker.add_child(leg)
	var bundle := MeshInstance3D.new()
	var bag := BoxMesh.new()
	bag.size=Vector3(0.27,0.32,0.23)
	bundle.mesh=bag
	bundle.position.y=0.32
	bundle.rotation.z=0.14
	bundle.material_override=BoardView._mat(Color(0.64,0.14,0.09),0.9)
	marker.add_child(bundle)


func _build_rescue(marker: MeshInstance3D) -> void:
	# A bundled unconscious figure rather than a treasure chest.
	var body := CapsuleMesh.new()
	body.radius=0.21
	body.height=1.10
	body.radial_segments=12
	body.rings=4
	marker.mesh=body
	marker.rotation.z=PI*0.5
	marker.material_override=BoardView._mat(Color("64566b"),0.9)
	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius=0.16
	sphere.height=0.32
	head.mesh=sphere
	head.position.y=0.48
	head.material_override=BoardView._mat(Color("c5ad8e"),0.95)
	marker.add_child(head)
