class_name CounterMagic
extends RefCounted
## List individual ongoing effects, not entire figures. Spawning is not an ongoing effect.
var c: GameController


func _init(controller: GameController) -> void:
	c = controller


func options(f: Figure) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var s := c.state
	for t in s.figures:
		if not t.in_play() or t.spell_effects.has("plane_walk") or Shooting.distance(f, t) > 24.0 or (t != f and not WizardEye.visible(s.board, f, t.pos)):
			continue
		for id: String in t.spell_effects:
			if s.spell_catalog.has(id) or id.begins_with("potion_"):
				result.append({"kind": "effect", "target": t.id, "spell": id, "label": "%s #%d — %s" % [t.label(), t.id, s.spell_catalog.get(id, {"name": id.trim_prefix("potion_").capitalize()})["name"]]})
		if t.elemental_shield > 0:
			result.append({"kind": "shield", "target": t.id, "spell": "elemental_shield", "label": "%s #%d — Elemental Shield" % [t.label(), t.id]})
		if t.controller_id >= 0:
			result.append({"kind": "control", "target": t.id, "spell": t.control_spell, "label": "%s #%d — %s" % [t.label(), t.id, t.control_spell.capitalize()]})
	for p in s.board.pieces:
		if p.cast_turn < 0:
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
		"terrain":
			var p: TerrainPiece = option["piece"]
			if s.board.pieces.has(p):
				c._magic.terrain.remove(p)
		"word":
			s.words.remove_at(int(option["word_index"]))
		"storm":
			s.storm_penalty = maxi(0, s.storm_penalty - 1)
	c.emit("spell_expired", {"id": option["target"], "spell": id})
