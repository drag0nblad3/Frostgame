class_name SpellActions
extends RefCounted
## Two-stage spellcasting: announce target, roll, choose Health, then resolve.

var c: GameController


func _init(controller: GameController) -> void:
	c = controller


func can_cast(id: String, target_id: int) -> bool:
	var s := c.state
	var f := s.active()
	var t := s.figure(target_id)
	if not c.can_act() or f == null or t == null or not t.in_play():
		return false
	if f.def.role not in ["wizard", "apprentice"] or Contact.in_combat(s.figures, f):
		return false
	if not s.spellbooks.get(f.side, {}).has(id) or not s.spell_catalog.has(id):
		return false
	var spell: Dictionary = s.spell_catalog[id]
	var kind: String = spell["kind"]
	if kind == "unimplemented":
		return false
	if kind == "self":
		return t == f and f.elemental_shield == 0
	if kind == "touch" and t != f and not Contact.touching(f.pos, t.pos):
		return false
	if not LineOfSight.check(s.board, f.pos, t.pos).clear and t != f:
		return false
	if spell.has("range") and Shooting.distance(f, t) > float(spell["range"]):
		return false
	if kind == "shot":
		return t != f and not Contact.in_combat(s.figures, t)
	if kind in ["heal", "resist"] and (t.def.traits.has("undead") or t.def.traits.has("construct")):
		return false
	if kind == "resist":
		return t.side != f.side
	if kind == "heal":
		return t.health < t.def.health
	return not t.spell_effects.has(id)


func start(id: String, target_id: int) -> bool:
	if not can_cast(id, target_id):
		return false
	var f := c.state.active()
	var raw := c.dice.d20()
	var total := CastingRoll.modified(raw, 0, f.def.role == "apprentice")
	var tn := int(c.state.spellbooks[f.side][id])
	c._spend(f)
	c.state.pending_cast = {"id": id, "caster": f.id, "target": target_id, "raw": raw, "total": total, "tn": tn}
	c.emit("cast_roll", c.state.pending_cast.duplicate())
	return true


func max_empowerment() -> int:
	var p := c.state.pending_cast
	if p.is_empty():
		return 0
	return CastingRoll.max_empowerment(p["total"], c.state.figure(p["caster"]).health)


func finish(health: int) -> bool:
	var s := c.state
	var p := s.pending_cast
	if p.is_empty() or health < 0 or health > max_empowerment():
		return false
	var f := s.figure(p["caster"])
	var t := s.figure(p["target"])
	var id: String = p["id"]
	var result := CastingRoll.resolve(p["total"], p["tn"], health, f.health)
	s.pending_cast = {}
	c._hurt(f, int(result["health_spent"]) + int(result["failure_damage"]), f, false)
	c.emit("cast_result", {"id": f.id, "spell": id, "target": t.id, "success": result["success"], "roll": result["roll"], "spent": health})
	if not result["success"] or not t.in_play():
		return true
	match id:
		"heal":
			_heal(t, 5)
		"elemental_shield":
			t.elemental_shield = 3
		"elemental_bolt", "bone_dart":
			_shot(f, t, int(s.spell_catalog[id]["power"]))
		"steal_health":
			if not StatRoll.succeeds(c.dice.d20(), t.effective_will(), result["roll"]):
				c._hurt(t, 3, f, false)
				if f.in_play():
					_heal(f, 3)
		_:
			t.spell_effects[id] = true
	c.emit("spell_effect", {"id": t.id, "spell": id})
	return true


func _heal(t: Figure, amount: int) -> void:
	var old := t.health
	t.health = mini(t.def.health, t.health + amount)
	c.emit("heal", {"id": t.id, "amount": t.health - old})


func _shot(f: Figure, t: Figure, power: int) -> void:
	var s := c.state
	var mod := Shooting.target_mod(LineOfSight.check(s.board, f.pos, t.pos))
	if t.def.traits.has("large"):
		mod -= 2
	if t.spell_effects.has("glow"):
		mod -= 3
	var ar := c.dice.d20()
	var dr := c.dice.d20()
	var a := ar + power
	var d := dr + mini(t.effective_fight() + mod, 10)
	var won := a > d
	if s.critical_hits:
		won = dr != 20 and (ar == 20 or won)
	var dmg := Damage.amount(a, 0, t.effective_armour(), ar, s.critical_hits) if won else 0
	c.emit("spell_shot", {"id": f.id, "target": t.id, "attack": a, "defence": d})
	c._hurt(t, dmg, f)
