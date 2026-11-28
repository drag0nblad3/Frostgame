class_name CounterMagic
extends RefCounted
## List individual ongoing effects, not entire figures. Spawning is not an ongoing effect.
## The controller owns this helper; avoid a RefCounted ownership cycle.
var _controller_ref: WeakRef
var c: GameController:
	get:
		return _controller_ref.get_ref() as GameController


func _init(controller: GameController) -> void:
	_controller_ref=weakref(controller)


func options(f: Figure) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var s := c.state
	for t in s.figures:
		if not t.in_play() or ScenarioNull.muted(t) or t.spell_effects.has("plane_walk") or Shooting.distance(f, t) > 24.0 or (t != f and not LineOfSight.spell_visible(s.board,f,t)):
			continue
		for id: String in t.spell_effects:
			if id in ["enchant_weapon","elemental_hammer"]:
				for weapon in WeaponEnchantment.ids(t,id):
					result.append({"kind":"weapon_enchantment","target":t.id,"spell":id,"weapon":weapon,"label":"%s #%d — %s (%s)"%[t.label(),t.id,id.replace("_"," ").capitalize(),weapon.replace("_"," ")]})
				continue
			if s.spell_catalog.has(id) or id.begins_with("potion_"):
				result.append({"kind": "effect", "target": t.id, "spell": id, "label": "%s #%d — %s" % [t.label(), t.id, s.spell_catalog.get(id, {"name": id.trim_prefix("potion_").capitalize()})["name"]]})
		if t.elemental_shield > 0:
			result.append({"kind": "shield", "target": t.id, "spell": "elemental_shield", "label": "%s #%d — Elemental Shield" % [t.label(), t.id]})
		if t.controller_id >= 0:
			result.append({"kind": "control", "target": t.id, "spell": t.control_spell, "label": "%s #%d — %s" % [t.label(), t.id, t.control_spell.capitalize()]})
	# Bridge surfaces are not ordinary TerrainPieces. Expose them only
	# when a physical sight ray reaches an actual bridge point.
	if not s.board.floor_layout.is_empty():
		var layout:=FloorLayout.from_dict(s.board.floor_layout)
		var eye:=Vector3(f.pos.x,f.elevation+1.5,f.pos.y)
		for entry: Dictionary in s.board.floor_layout.get("bridges",[]):
			var id:=str(entry["surface"]["id"])
			var index:=layout.index_of(id)
			if index<0:
				continue
			var surface:=layout.surfaces[index]
			var at:=surface.rect.get_center()
			var target:=Vector3(at.x,surface.height_at(at)+0.06,at.y)
			if eye.distance_to(target)<=24.0 and LayeredSight.clear(layout,eye,target) and not BattleBoundary.blocks_segment(s.board.boundaries,f.pos,at,"sight",f):
				result.append({"kind":"floor_bridge","target":f.id,"spell":"bridge","surface":id,"label":"Conjured bridge · "+id})
	for p in s.board.pieces:
		if p.cast_turn<0:
			continue
		if not s.board.floor_layout.is_empty():
			if p.surface_id.is_empty():
				continue
			var at:=p.rect.get_center()
			var edge:=f.pos.clamp(p.rect.position,p.rect.end).lerp(f.pos,0.02)
			var layout:=s.board.floor_geometry()
			if LineOfSight.floor_point_visible(s.board,layout,f,Vector3(at.x,p.base_height,at.y)) or LineOfSight.floor_point_visible(s.board,layout,f,Vector3(edge.x,p.base_height+minf(p.kind.height,1.0),edge.y)):
				result.append({"kind":"terrain","target":f.id,"piece":p,"spell":p.kind.id.trim_prefix("spell_"),"label":p.kind.name+" · "+p.surface_id})
			continue
		var center := p.rect.get_center()
		if f.pos.distance_to(center) <= 24 and (WizardEye.visible(s.board, f, center) or _visible_edge(f, p)):
			result.append({"kind": "terrain", "target": f.id, "piece": p, "spell": p.kind.id.trim_prefix("spell_"), "label": "%s at %.1f, %.1f" % [p.kind.name, center.x, center.y]})
	for i in s.words.size():
		var word := s.words[i]
		result.append({"kind": "word", "target": f.id, "spell": word["spell"], "word_index": i, "label": "%s: %s" % [s.spell_catalog[word["spell"]]["name"], s.spell_catalog[word["chosen"]]["name"]]})
	if s.storm_penalty > 0:
		result.append({"kind": "storm", "target": f.id, "spell": "call_storm", "label": "Call Storm (one casting)"})
	return result


func _visible_edge(f: Figure, p: TerrainPiece) -> bool:
	var b := c.state.board
	# Sight can reach the near face of opaque conjured terrain.
	var nearest := Vector2(clampf(f.pos.x, p.rect.position.x, p.rect.end.x), clampf(f.pos.y, p.rect.position.y, p.rect.end.y))
	var at := nearest.lerp(f.pos, 0.02)
	return f.pos.distance_to(at) <= 24 and WizardEye.visible(b, f, at)


func apply(option: Dictionary) -> void:
	var s := c.state
	var t := s.figure(option["target"])
	var id: String = option["spell"]
	match str(option["kind"]):
		"weapon_enchantment":
			if t!=null:
				WeaponEnchantment.remove(t,str(option["weapon"]),id)
		"effect":
			if t == null:
				return
			if id == "potion_shrinking":
				c._loot.cancel_shrinking(t)
			t.spell_effects.erase(id)
			if id == "petrify":
				t.petrified_skip = false
		"shield":
			t.elemental_shield = 0
		"control":
			c._magic.summons.release(t)
		"floor_bridge":
			LayeredBridge.remove(c,str(option["surface"]))
		"terrain":
			var p: TerrainPiece = option["piece"]
			if s.board.pieces.has(p):
				c._magic.terrain.remove(p)
		"word":
			s.words.remove_at(int(option["word_index"]))
		"storm":
			s.storm_penalty = maxi(0, s.storm_penalty - 1)
	c.emit("spell_expired", {"id": option["target"], "spell": id})
