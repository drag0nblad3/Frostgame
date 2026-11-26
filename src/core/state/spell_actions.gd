class_name SpellActions
extends RefCounted
## Two-stage spellcasting: announce target, roll, choose Health, then resolve.

var c: GameController
var summons: SummonActions
var terrain: TerrainMagic
var movement: MagicMovement
var counter: CounterMagic
var illusions: IllusionActions
var resistance: ResistanceActions
var weapons: WeaponActions


func _init(controller: GameController) -> void:
	c = controller
	summons = SummonActions.new(c)
	terrain = TerrainMagic.new(c)
	movement = MagicMovement.new(c)
	counter = CounterMagic.new(c)
	illusions = IllusionActions.new(c)
	resistance = ResistanceActions.new(c)
	weapons = WeaponActions.new(c)


func can_cast(id: String, target_id: int) -> bool:
	var s := c.state
	var f := s.active()
	var t := s.figure(target_id)
	if not c.can_act() or f == null or t == null or not t.in_play():
		return false
	if f.def.role not in ["wizard", "apprentice"] or Contact.in_combat(s.figures, f):
		return false
	if not available_spell(f, id) or not s.spell_catalog.has(id):
		return false
	var spell: Dictionary = s.spell_catalog[id]
	var kind: String = spell["kind"]
	if kind in ["unimplemented", "placement", "counter"]:
		return false
	if kind == "self":
		return t == f and f.elemental_shield == 0
	if kind == "self_area":
		return t == f
	if id == "true_sight":
		return t == f and not f.spell_effects.has(id)
	if id == "time_store":
		return t == f and not f.spell_effects.has(id) and f.actions_left == 2 and not f.acted and f.moves_taken == 0 and not s.group.in_progress()
	if id == "time_walk":
		return t == f and f.def.role == "wizard" and s.phase == Phase.WIZARD and f.last_time_walk != s.turn
	if not IllusionRules.visible_to(s.figures, f, t):
		return false
	if f.spell_effects.has("blinding_light") and kind != "touch":
		return false
	if kind == "touch" and t != f and Shooting.distance(f, t) > 1.0:
		return false
	if not LineOfSight.check(s.board, f.pos, t.pos).clear and t != f:
		return false
	if spell.has("range") and Shooting.distance(f, t) > float(spell["range"]):
		return false
	if kind == "shot":
		return t != f
	if kind == "area_shot":
		return t.side != f.side
	if id == "fast_act":
		return t != f and not t.activated and not s.is_fast(t) and (t.side == f.side or t.side < 0) and not s.group.members.has(t.id)
	if id == "leap":
		return t.side == f.side and not t.spell_effects.has("petrify") and not movement.points(f, t, id, true).is_empty()
	if id == "transpose":
		for other in s.figures:
			if movement.can_swap(f, t, other):
				return true
		return false
	if id == "push":
		return t != f
	if id == "blink":
		return true
	if id == "enchant_armour":
		return t.def.role == "soldier" and t.def.armour >= 11 and not t.spell_effects.has(id)
	if SummonActions.CONTROL.has(id):
		return summons.can_control(f, t, id)
	if id == "destroy_undead":
		return t.def.traits.has("undead")
	if kind in ["heal", "resist"] and (t.def.traits.has("undead") or t.def.traits.has("construct")):
		return false
	if kind == "resist":
		return t.side != f.side
	if kind == "heal":
		return t.health < t.def.health
	return not t.spell_effects.has(id)


func start(id: String, target_id: int) -> bool:
	if not can_cast(id, target_id) or id in ["leap", "transpose"]:
		return false
	return _roll(id, target_id)


func counter_options(id: String) -> Array[Dictionary]:
	var f := c.state.active()
	var empty: Array[Dictionary] = []
	if id not in ["dispel", "spell_eater", "decay"] or not c.can_act() or f == null or f.def.role not in ["wizard", "apprentice"] or Contact.in_combat(c.state.figures, f) or f.spell_effects.has("blinding_light"):
		return empty
	if not available_spell(f, id):
		return empty
	return weapons.options(f) if id == "decay" else counter.options(f)


func start_counter(id: String, index: int) -> bool:
	var options := counter_options(id)
	if index < 0 or index >= options.size():
		return false
	var option := options[index]
	return _roll(id, option["target"], null, false, -1, option)


func start_move(id: String, target_id: int, at: Vector2) -> bool:
	if id != "leap" or not can_cast(id, target_id) or not movement.can_land(c.state.active(), c.state.figure(target_id), id, at):
		return false
	return _roll(id, target_id, at)


func start_swap(first: int, second: int) -> bool:
	if not can_cast("transpose", first) or not can_cast("transpose", second) or not movement.can_swap(c.state.active(), c.state.figure(first), c.state.figure(second)):
		return false
	return _roll("transpose", first, null, false, second)


func placement_points(id: String, first_only: bool = false, rotated: bool = false) -> Array[Vector2]:
	var f := c.state.active()
	var empty: Array[Vector2] = []
	if not c.can_act() or f == null or f.def.role not in ["wizard", "apprentice"] or Contact.in_combat(c.state.figures, f):
		return empty
	if not available_spell(f, id) or not is_placement(id):
		return empty
	if f.spell_effects.has("blinding_light") and id not in ["raise_zombie", "summon_demon", "illusionary_soldier"]:
		return empty
	if id == "teleport":
		return movement.points(f, f, id, first_only)
	if TerrainMagic.SPELLS.has(id):
		return terrain.points(f, id, rotated, first_only)
	return summons.points(f, id, first_only)


func is_placement(id: String) -> bool:
	return id == "teleport" or SummonActions.PLACEMENT.has(id) or TerrainMagic.SPELLS.has(id)


func start_at(id: String, at: Vector2, rotated: bool = false) -> bool:
	if placement_points(id, true, rotated).is_empty():
		return false
	var f := c.state.active()
	if id == "teleport":
		if not movement.can_land(f, f, id, at):
			return false
	elif TerrainMagic.SPELLS.has(id):
		if not terrain.can_place(f, id, at, rotated):
			return false
	elif not summons.can_place(f, id, at):
		return false
	return _roll(id, c.state.active_id, at, rotated)


func _roll(id: String, target_id: int, at: Variant = null, rotated: bool = false, second: int = -1, effect: Dictionary = {}) -> bool:
	var f := c.state.active()
	illusions.reveal(f)
	var known: bool = c.state.spellbooks.get(f.side, {}).has(id)
	var scroll := not known and ScrollActions.consume(f, id)
	var raw := 14 if scroll else c.dice.d20()
	var total := 14 if scroll else CastingRoll.modified(raw, f.roll_penalty() - (2 if f.spell_effects.has("furious_quill") else 0), f.def.role == "apprentice")
	var tn := int(c.state.spellbooks.get(f.side, {}).get(id, c.state.spell_catalog[id]["number"]))
	c._spend(f)
	c.state.pending_cast = {"id": id, "caster": f.id, "target": target_id, "raw": raw, "total": total, "tn": tn, "scroll": scroll}
	if at != null:
		c.state.pending_cast["at"] = at
		c.state.pending_cast["rotated"] = rotated
	c.state.pending_cast["second"] = second
	if not effect.is_empty():
		c.state.pending_cast["effect"] = effect
	c.emit("cast_roll", c.state.pending_cast.duplicate())
	if id == "spell_eater":
		c._hurt(f, 1, f, false)
	return true


func max_empowerment() -> int:
	var p := c.state.pending_cast
	if p.is_empty() or p.get("scroll", false):
		return 0
	var f := c.state.figure(p["caster"])
	var resources := maxi(0, f.health) + PowerPool.available(f)
	if p["id"] == "summon_demon":
		return 0 if int(p["raw"]) == 1 else resources
	return CastingRoll.max_empowerment(p["total"], resources)


func finish(health: int) -> bool:
	var s := c.state
	var p := s.pending_cast
	if p.is_empty() or health < 0 or health > max_empowerment():
		return false
	var f := s.figure(p["caster"])
	var t := s.figure(p["target"])
	var id: String = p["id"]
	var result := CastingRoll.resolve(p["total"], p["tn"], health, maxi(0, f.health) + PowerPool.available(f), false, 100 if id == "summon_demon" else 18)
	if p.get("scroll", false):
		result = {"success": true, "roll": 14, "health_spent": 0, "failure_damage": 0}
	elif id == "summon_demon" and int(p["raw"]) == 1:
		result["success"] = false
	s.pending_cast = {}
	var power := PowerPool.spend(f, int(result["health_spent"]))
	var hp := int(result["health_spent"]) - power
	c._hurt(f, hp + int(result["failure_damage"]), f, false)
	c.emit("cast_result", {"id": f.id, "spell": id, "target": t.id, "success": result["success"], "roll": result["roll"], "spent": hp, "power": power, "tn": p["tn"], "failure_damage": result["failure_damage"], "scroll": p.get("scroll", false)})
	if id == "summon_demon" and int(p["raw"]) == 1 and not p.get("scroll", false):
		summons.miscast_demon(f)
		return true
	if not result["success"]:
		return true
	if id in ["dispel", "spell_eater"]:
		counter.apply(p["effect"])
		return true
	if id == "decay":
		weapons.destroy(t, p["effect"]["weapon"])
		return true
	if TerrainMagic.SPELLS.has(id):
		terrain.apply(f, id, p["at"], p["rotated"], int(result["roll"]))
		return true
	if SummonActions.PLACEMENT.has(id):
		summons.spawn(f, id, p["at"], int(p["total"]) + health, int(p["tn"]))
		illusions.sweep()
		return true
	if not t.in_play():
		return true
	if SummonActions.CONTROL.has(id):
		summons.apply_control(f, t, id, int(result["roll"]))
		return true
	match id:
		"fast_act":
			s.queue_fast(t, f.side)
		"time_store":
			f.spell_effects[id] = true
			f.stored_action_turn = s.turn
			f.actions_left = 0
		"time_walk":
			if f.last_time_walk == s.turn - 1:
				c._hurt(f, 8, f, false)
			f.last_time_walk = s.turn
			if f.in_play():
				f.spell_effects[id] = true
				f.walk_phases.assign([Phase.APPRENTICE, Phase.SOLDIER])
		"invisibility", "true_sight":
			t.spell_effects[id] = true
			illusions.sweep()
		"teleport", "leap":
			movement.move(t, p["at"], true)
		"push":
			movement.push(f, t)
		"blink":
			movement.blink(f, t, int(result["roll"]))
		"transpose":
			movement.transpose(f, t, s.figure(p["second"]), int(result["roll"]))
		"heal":
			_heal(t, 5)
		"mind_lock":
			if t.control_spell == "mind_control":
				summons.release(t)
			t.spell_effects[id] = true
		"elemental_shield":
			t.elemental_shield = 3
		"elemental_bolt", "bone_dart", "poison_dart":
			t = ShotTarget.randomize(c.dice, s.figures, t)
			var old_health := t.health
			_shot(f, t, int(s.spell_catalog[id]["power"]), null, id == "elemental_bolt")
			if id == "poison_dart" and t.health < old_health:
				c.poison(t)
		"call_storm":
			s.storm_penalty = mini(5, s.storm_penalty + 1)
		"blinding_light", "petrify":
			var bonus := 8 if id == "petrify" and t.def.traits.has("large") else 0
			resistance.attempt(t, int(result["roll"]), _resisted_status.bind(t, id, int(result["roll"])), bonus)
			return true
		"banish":
			for other in s.figures:
				if other.in_play() and other.def.traits.has("demon") and LineOfSight.check(s.board, f.pos, other.pos).clear:
					_banish(f, other, int(result["roll"]), 4)
		"scatter_shot":
			for other in s.figures:
				if other.in_play() and other.side != f.side and Shooting.distance(f, other) <= 12 and LineOfSight.check(s.board, f.pos, other.pos).clear:
					_shot(f, ShotTarget.randomize(c.dice, s.figures, other), 0)
		"destructive_sphere":
			for other in s.figures:
				if other != f and other.in_play() and Shooting.distance(f, other) <= 3:
					_direct_attack(f, other, 5)
		"slow", "curse", "furious_quill":
			t.spell_effects[id] = int(result["roll"])
			if id == "slow" and t == s.active():
				t.actions_left = 0
		"elemental_ball":
			var affected: Array[Figure] = []
			for other in s.figures:
				if other.in_play() and Shooting.distance(t, other) <= 1.0 and (other == t or LineOfSight.check(s.board, t.pos, other.pos).clear):
					for member in ShotTarget.participants(s.figures, other):
						if not affected.has(member):
							affected.append(member)
			for other in affected:
				_shot(f, other, 5, t.pos if other != t else f.pos, true)
		"destroy_undead":
			var raw := c.dice.d20()
			var total := raw + t.effective_will() + t.roll_penalty()
			if not StatRoll.succeeds(raw, t.effective_will() + t.roll_penalty(), result["roll"]):
				c._hurt(t, t.health if t.effective_will() <= 2 else maxi(0, int(result["roll"]) - total) * 3, f, false)
		"steal_health":
			resistance.attempt(t, int(result["roll"]), _resisted_steal.bind(f, t))
			return true
		_:
			t.spell_effects[id] = true
	c.emit("spell_effect", {"id": t.id, "spell": id})
	return true


func _heal(t: Figure, amount: int) -> void:
	var old := t.health
	t.health = mini(t.def.health, t.health + amount)
	if t.health > old:
		t.poisoned = false
	c.emit("heal", {"id": t.id, "amount": t.health - old})


func _shot(f: Figure, t: Figure, power: int, origin: Variant = null, elemental: bool = false) -> void:
	if not t.in_play():
		return
	var s := c.state
	var from: Vector2 = f.pos if origin == null else origin
	var mod := Shooting.target_mod(LineOfSight.check(s.board, from, t.pos)) + (1 if f.moves_taken > 0 else 0)
	if t.def.traits.has("large"):
		mod -= 2
	var ar := c.dice.d20()
	var dr := c.dice.d20()
	var a := ar + mini(power + (3 if t.spell_effects.has("glow") else 0), 10) + f.roll_penalty()
	var d := dr + mini(t.effective_fight() + mod, 10) + t.roll_penalty()
	var won := a > d
	if s.critical_hits:
		won = dr != 20 and (ar == 20 or won)
	var dmg := Damage.amount(a, 0, t.effective_armour(), ar, s.critical_hits) if won else 0
	if elemental and MagicEquipment.bonus(t, "absorb") > 0:
		dmg = ceili(dmg / 2.0)
	c.emit("spell_shot", {"id": f.id, "target": t.id, "attack": a, "defence": d})
	c._hurt(t, dmg, f)


func _resist_effect(f: Figure, id: String) -> void:
	if f.in_play() and f.spell_effects.has(id) and StatRoll.succeeds(c.dice.d20(), f.effective_will() + f.roll_penalty(), int(f.spell_effects[id])):
		f.spell_effects.erase(id)
		c.emit("spell_expired", {"id": f.id, "spell": id})


func on_activate(f: Figure) -> void:
	_resist_effect(f, "furious_quill")


func on_end_activation(f: Figure) -> void:
	f.petrified_skip = false
	_resist_effect(f, "slow")
	if f.in_play() and f.control_spell == "mind_control" and StatRoll.succeeds(c.dice.d20(), f.effective_will() + f.roll_penalty(), f.control_roll):
		summons.release(f)


func on_end_turn() -> void:
	terrain.expire()
	for f in c.state.figures:
		_resist_effect(f, "curse")
		_resist_effect(f, "blinding_light")


func _banish(f: Figure, t: Figure, roll: int, threshold: int) -> void:
	var raw := c.dice.d20()
	var will := t.effective_will() + t.roll_penalty()
	if not StatRoll.succeeds(raw, will, roll):
		c._hurt(t, t.health if t.effective_will() <= threshold else maxi(0, roll - raw - will) * 3, f, false)


func _direct_attack(f: Figure, t: Figure, power: int) -> void:
	var a := c.dice.d20() + power
	var d := c.dice.d20() + t.effective_fight() + t.roll_penalty()
	if a > d:
		c._hurt(t, maxi(0, a - t.effective_armour()), f, false)


func can_cancel(target: int) -> bool:
	var f := c.state.active()
	var t := c.state.figure(target)
	return c.can_act() and f != null and t != null and summons.cancelable(f, t)


func cancel(target: int) -> bool:
	if not can_cancel(target):
		return false
	var f := c.state.active()
	c._spend(f)
	summons.cancel(f, c.state.figure(target))
	return true


func _resisted_status(success: bool, t: Figure, id: String, roll: int) -> void:
	if success or not t.in_play():
		return
	t.spell_effects[id] = roll
	if id == "petrify":
		t.petrified_skip = true
	c.emit("spell_effect", {"id": t.id, "spell": id})


func _resisted_steal(success: bool, f: Figure, t: Figure) -> void:
	if success or not t.in_play():
		return
	c._hurt(t, 3, f, false)
	if f.in_play():
		_heal(f, 3)
	c.emit("spell_effect", {"id": t.id, "spell": "steal_health"})


func available_spell(f: Figure, id: String) -> bool:
	return c.state.spellbooks.get(f.side, {}).has(id) or ScrollActions.has_scroll(f, id)


func available_spells(f: Figure) -> Array[String]:
	var out: Array[String] = []
	for id: String in c.state.spellbooks.get(f.side, {}):
		out.append(id)
	for item in f.items:
		var id := str(item.get("scroll", ""))
		if id != "" and not out.has(id):
			out.append(id)
	return out


func can_insure() -> bool:
	var p := c.state.pending_cast
	if p.is_empty() or p.get("scroll", false):
		return false
	var failed: bool = int(p["total"]) < int(p["tn"]) or (p["id"] == "summon_demon" and int(p["raw"]) == 1)
	return failed and ScrollActions.has_scroll(c.state.figure(p["caster"]), p["id"])


func insure() -> bool:
	if not can_insure():
		return false
	var p := c.state.pending_cast
	ScrollActions.consume(c.state.figure(p["caster"]), p["id"])
	p["scroll"] = true
	p["total"] = 14
	return finish(0)
