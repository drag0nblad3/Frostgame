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
			CombatVfx.magic(self,v.position,"portal",Color("b3a0ee"),1.1,speed)
			_hold(0.85)
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
			var path: PackedVector3Array=d["path"]
			if d.get("teleport",false) and path.size()>1:
				_animate_portal(_view(d["id"]),path[-1],"teleport")
			else:
				if d.get("leap",false) or d.get("jump",false):
					CombatVfx.sparks(self,path[0],Color("d5e1e7"),0.55,speed,0.1)
				_animate_layered_move(_view(d["id"]),path)
		"move", "push_back", "force_combat":
			var id:=str(d.get("visual_spell",""))
			var path: PackedVector2Array=d["path"]
			if id in ["teleport","transpose"] and path.size()>1:
				_animate_portal(_view(d["id"]),TableSpace.to_world(path[-1],float(d.get("end_height",state.board.height_at(path[-1])))),id)
			elif id=="leap" and path.size()>1:
				_animate_leap(_view(d["id"]),TableSpace.to_world(path[-1],float(d.get("end_height",state.board.height_at(path[-1])))))
			else:
				_animate_move(_view(d["id"]),path)
		"terrain_fall":
			var f := state.figure(d["id"])
			var falling := _view(f.id)
			var landing:=TableSpace.to_world(f.pos,f.elevation)
			var fall:=create_tween()
			fall.tween_property(falling,"position",landing,0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			fall.tween_callback(CombatVfx.sparks.bind(self,landing,Color("b7c8d3"),0.6,speed,0.15))
			fall.tween_interval(0.35)
			_wait_for(fall)
		"terrain_changed","magic_burst","rune_exploded":
			if d.get("at") is Vector2:
				var id:=str(d.get("spell","explosive_rune"))
				var point: Vector2=d["at"]
				var at:=TableSpace.to_world(point,float(d.get("height",state.board.height_at(point)))+0.07)
				var color:=SpellVisuals.color_for(id,state)
				var radius:=float(d.get("radius",2.0))
				CombatVfx.magic(self,at,_motif(id),color,radius,speed,not d.get("created",true))
				if e.type!="terrain_changed":
					CombatVfx.flash(self,at+Vector3.UP*0.5,color,radius,speed)
					CombatVfx.sparks(self,at,color,radius,speed)
				_hold(1.1)
		"magic_impact":
			if views.has(d["id"]):
				var target:=_view(d["id"])
				var id:=str(d["spell"])
				CombatVfx.shot_impact(self,target.position+Vector3.UP*target.body_height(),SpellVisuals.color_for(id,state),bool(d["hit"]),true,id,speed)
				_hold(0.85)
		"resistance_result":
			if views.has(d["id"]):
				var target:=_view(d["id"])
				CombatVfx.magic(self,target.position,"ward" if d["success"] else "runes",Color("a3e7f0") if d["success"] else Color("b69add"),0.95,speed,not d["success"])
				_float_text(target,"RESISTED" if d["success"] else "RESISTANCE FAILED",Color("e5d1a0"))
		"allegiance", "spell_effect", "spell_expired", "weapon_selected", "weapon_destroyed", "poison", "null_field", "shield_absorb":
			var affected := _view(d["id"])
			affected.refresh(state.figure(d["id"]))
			if e.type in ["spell_effect","spell_expired","poison","null_field","shield_absorb","weapon_destroyed"]:
				var effect := str(d.get("spell",e.type)).replace("_"," ").capitalize()
				if e.type=="spell_expired":
					effect+=" ends"
				var id:=str(d.get("spell",e.type))
				var color:=SpellVisuals.color_for(id,state)
				var kind:=_motif(id)
				if e.type=="shield_absorb":
					kind="ward"
					color=Color("83d5f7")
					effect="Absorbed %d"%int(d.get("amount",0))
				elif e.type=="poison":
					kind="swarm"
					color=Color("92ce54")
				elif e.type=="null_field":
					kind="runes"
					color=Color("9baebd")
				CombatVfx.magic(self,affected.position,kind,color,1.0,speed,e.type in ["spell_expired","null_field"])
				_float_text(affected,effect,color.lightened(0.3))
		"cast_result":
			if views.has(d["id"]):
				var caster := _view(d["id"])
				var color := SpellVisuals.color_for(str(d["spell"]),state)
				var id:=str(d["spell"])
				SpellVisuals.sigil(self,caster.position+Vector3.UP*0.08,color,1.25)
				CombatVfx.magic(self,caster.position,_motif(id),color,1.15,speed,not d["success"])
				if d["success"]:
					CombatVfx.flash(self,caster.position+Vector3.UP*caster.body_height(),color,0.45,speed)
				else:
					CombatVfx.sparks(self,caster.position+Vector3.UP*caster.body_height(),Color("c8a0ac"),0.55,speed)
				var pose_tween := create_tween()
				pose_tween.tween_method(caster.cast_pose,0.0,1.0,0.40)
				pose_tween.tween_method(caster.cast_pose,1.0,0.0,0.35)
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
			_animate_shot(_view(d["id"]),_view(d["target"]),e.type=="spell_shot" or d.get("wraith",false) or d.get("ammo",false),str(d.get("spell","")),d.get("origin",null),int(d.get("dmg",0))>0,str(d.get("weapon","bow")))
		"fight":
			var a := _view(d["id"])
			var b := _view(d["target"])
			if int(d["winner"]) == int(d["target"]):
				_animate_lunge(b,a,false,str(d.get("b_weapon","hand_weapon")),state.critical_hits and int(d.get("b_roll",0))==20)
			else:
				_animate_lunge(a,b,int(d["winner"])<0,str(d.get("a_weapon","hand_weapon")),state.critical_hits and int(d.get("a_roll",0))==20)
		"damage":
			var v := _view(d["id"])
			v.refresh(state.figure(d["id"]))
			CombatVfx.flash(self,v.position+Vector3.UP*v.body_height(),Color("f39882"),0.46,speed)
			CombatVfx.sparks(self,v.position+Vector3.UP*v.body_height(),Color("e2ac86"),0.45,speed)
			_float_text(v, "-%d" % d["amount"])
		"out_of_action":
			var fallen := _view(d["id"])
			CombatVfx.sparks(self,fallen.position+Vector3.UP*0.15,Color("b8c7d0"),0.8,speed,0.25)
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



func _motif(id: String) -> String:
	return CombatVfx.motif(id,str(state.spell_catalog.get(id,{}).get("school","")))


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


func _animate_portal(v: FigureView,destination: Vector3,id: String) -> void:
	var color:=SpellVisuals.color_for(id,state)
	var origin:=v.position
	CombatVfx.magic(self,origin,"portal",color,1.1,speed)
	var t:=create_tween()
	t.tween_interval(0.25)
	t.tween_callback(v.hide)
	t.tween_callback(CombatVfx.flash.bind(self,origin+Vector3.UP*0.8,color,0.55,speed))
	t.tween_property(v,"position",destination,0.0)
	t.tween_callback(CombatVfx.magic.bind(self,destination,"portal",color,1.1,speed))
	t.tween_interval(0.25)
	t.tween_callback(v.show)
	t.tween_callback(CombatVfx.sparks.bind(self,destination,color,0.65,speed))
	t.tween_interval(0.60)
	_wait_for(t)


func _animate_leap(v: FigureView,destination: Vector3) -> void:
	var start:=v.position
	var color:=SpellVisuals.color_for("leap",state)
	v.face_toward(destination)
	CombatVfx.magic(self,start,"portal",color,0.85,speed)
	var t:=create_tween()
	var arc:=func(f: float) -> void:
		v.position=start.lerp(destination,f)+Vector3.UP*4.0*f*(1.0-f)*2.0
	t.tween_method(arc,0.0,1.0,0.7)
	t.tween_callback(CombatVfx.magic.bind(self,destination,"portal",color,0.85,speed,true))
	t.tween_callback(CombatVfx.sparks.bind(self,destination,Color("c9d9e3"),0.55,speed,0.2))
	t.tween_interval(0.55)
	_wait_for(t)


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


func _animate_shot(from: FigureView,to: FigureView,magic: bool=false,spell: String="",origin: Variant=null,damaging: bool=true,weapon: String="bow") -> void:
	from.face_toward(to.position)
	var color := SpellVisuals.color_for(spell,state) if magic else Color(0.92,0.78,0.50)
	var bolt := SpellVisuals.projectile(spell,magic,color,weapon)
	add_child(bolt)
	var start := from.position + Vector3.UP*from.body_height()
	if origin is Vector2:
		start = TableSpace.to_world(origin,state.board.height_at(origin)+1.0)
	elif origin is Vector3:
		start=origin
	var destination := to.position + Vector3.UP*to.body_height()
	bolt.position = start
	if start.distance_squared_to(destination)>0.001:
		bolt.look_at(destination)
	bolt.hide()
	var t := create_tween()
	t.tween_method(from.cast_pose if magic else from.shot_pose, 0.0, 0.88, 0.20).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	t.tween_callback(bolt.show)
	t.tween_callback(CombatVfx.flash.bind(self,start,color,0.34 if magic else 0.14,speed))
	var travel:=clampf(start.distance_to(destination)*0.055,0.20,1.25)
	t.tween_property(bolt,"position",destination,travel)
	if magic:
		t.parallel().tween_property(bolt,"rotation:z",bolt.rotation.z+TAU,travel)
	t.parallel().tween_method(from.cast_pose if magic else from.shot_pose, 0.88, 0.0, 0.23).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_callback(bolt.queue_free)
	t.tween_callback(CombatVfx.shot_impact.bind(self,destination,color,damaging,magic,spell,speed))
	if damaging:
		t.tween_method(to.recoil_pose,0.0,0.65,0.15)
		t.tween_method(to.recoil_pose,0.65,0.0,0.20)
	else:
		t.tween_method(to.guard_pose,0.0,0.75,0.14)
		t.tween_method(to.guard_pose,0.75,0.0,0.17)
	if spell == "elemental_ball" and damaging:
		t.tween_callback(BattleEffects.pulse.bind(self,to.position+Vector3.UP*0.15,color,1.7))
	t.tween_interval(0.5)
	_wait_for(t)


func _animate_lunge(a: FigureView,b: FigureView,tied: bool=false,weapon: String="hand_weapon",critical: bool=false) -> void:
	a.face_toward(b.position)
	b.face_toward(a.position)
	var home := a.position
	var toward := home.lerp(b.position, 0.35)
	var t := create_tween()
	t.tween_method(a.attack_pose, 0.0, -0.45, 0.17).set_trans(Tween.TRANS_SINE)
	t.parallel().tween_method(b.guard_pose,0.0,1.0,0.17)
	t.tween_property(a, "position", toward, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.parallel().tween_method(a.attack_pose, -0.45, 1.0, 0.16)
	var impact:=toward.lerp(b.position,0.5)+Vector3.UP*0.85
	t.tween_callback(CombatVfx.strike.bind(self,toward+Vector3.UP*0.85,b.position-home,weapon,critical,speed))
	t.tween_callback(BattleEffects.clash.bind(self,impact,b.position-home,tied))
	t.tween_callback(CombatVfx.sparks.bind(self,impact,Color("ffe1a2") if critical else Color("cfdbe5"),1.1 if critical else 0.65,speed,0.45))
	if critical:
		t.tween_callback(CombatVfx.flash.bind(self,impact,Color("ffd58d"),0.8,speed))
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
