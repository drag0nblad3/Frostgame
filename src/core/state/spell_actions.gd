class_name SpellActions
extends RefCounted
## Two-stage spellcasting: announce target, roll, choose Health, then resolve.

var c: GameController
var shatter := Shatterstar.new()
var summons: SummonActions
var terrain: TerrainMagic
var movement: MagicMovement
var counter: CounterMagic
var illusions: IllusionActions
var resistance: ResistanceActions
var weapons: WeaponActions
var treasure_magic: TreasureMagic
var crumble: CrumbleActions
var beauty: BeautyActions
var eye: WizardEye


func _init(controller: GameController) -> void:
	c = controller
	summons = SummonActions.new(c)
	terrain = TerrainMagic.new(c)
	movement = MagicMovement.new(c)
	counter = CounterMagic.new(c)
	illusions = IllusionActions.new(c)
	resistance = ResistanceActions.new(c)
	weapons = WeaponActions.new(c)
	treasure_magic = TreasureMagic.new(c)
	crumble = CrumbleActions.new(c)
	beauty = BeautyActions.new(c)
	eye = WizardEye.new(c)


func can_cast(id: String, target_id: int) -> bool:
	var s := c.state
	if not s.board.floor_layout.is_empty() and not LayeredFigureSpells.SUPPORTED.has(id):
		return false
	var f := s.active()
	var t := s.figure(target_id)
	if not c.can_act() or f == null or t == null or f.ring_side!=t.ring_side or not t.in_play() or RedKingMadMan.is_ryce(t) or ScenarioNull.muted(t) or t.def.traits.has("antithetical_magic"):
		return false
	if f.def.role not in ["wizard", "apprentice"] or Contact.in_combat(s.figures, f):
		return false
	if not available_spell(f, id) or not s.spell_catalog.has(id):
		return false
	var spell: Dictionary = s.spell_catalog[id]
	var kind: String = spell["kind"]
	if RedKingTethers.pylon(t) and kind not in ["shot","area_shot"]:
		return false
	if kind in ["unimplemented", "ritual", "placement", "counter", "treasure"]:
		return false
	if kind == "self":
		return t == f and f.elemental_shield == 0
	if kind == "self_area":
		return t == f
	if t.spell_effects.has("plane_walk"):
		return false
	if id == "plane_walk":
		return t == f and f.last_plane_attempt != s.turn
	if id == "beauty":
		return t == f and not f.spell_effects.has(id)
	if BeautyActions.blocked(s, f, t):
		return false
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
	var limit := 1.0 if kind == "touch" else float(spell.get("range", 24.0))
	if t != f:
		if not s.board.floor_layout.is_empty():
			if not LayeredFigureSpells.visible(s.board,f,t,limit):
				return false
		elif kind == "area_shot":
			if Shooting.distance(f, t) > limit or not LineOfSight.check(s.board, f.pos, t.pos).clear:
				return false
		elif not WizardEye.visible(s.board, f, t.pos, limit):
			return false
	if kind == "shot":
		return t != f
	if kind == "area_shot":
		return t.side != f.side
	if id == "fast_act":
		return t != f and not t.activated and not s.is_fast(t) and (t.side == f.side or t.side < 0) and not s.group.members.has(t.id)
	if id == "possess":
		if t.side != f.side or t.def.role in ["wizard", "apprentice"] or t.is_demon() or s.group.members.has(t.id):
			return false
		for other in s.figures:
			if other.in_play() and int(other.spell_effects.get("possess", -1)) == f.id:
				return false
		return true
	if id == "plague_of_insects":
		return not t.insects_immune() and not t.spell_effects.has(id)
	if id=="mind_control" and t.def.traits.has("immune_mind_control"):
		return false
	if id=="control_demon" and t.def.traits.has("immune_control_demon"):
		return false
	if id == "suggestion":
		return t != f and not t.def.traits.has("mind_lock") and not t.spell_effects.has("mind_lock")
	if id == "bones_of_the_earth":
		return not t.def.traits.has("large") and t.elevation < 0.01 and not t.spell_effects.has(id)
	if id == "leap":
		return t.side == f.side and not t.spell_effects.has("bones_of_the_earth") and not t.spell_effects.has("petrify") and not movement.points(f, t, id, true).is_empty()
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
	if id == "strike_dead":
		return t != f and not t.def.traits.has("undead") and not t.def.traits.has("construct")
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
	if not can_cast(id, target_id) or id in ["leap", "transpose", "suggestion"]:
		return false
	return _roll(id, target_id)


func counter_options(id: String) -> Array[Dictionary]:
	var f := c.state.active()
	var empty: Array[Dictionary] = []
	if id not in ["dispel", "spell_eater", "decay", "power_word", "draining_word", "crumble", "wizard_eye"] or not c.can_act() or f == null or f.def.role not in ["wizard", "apprentice"] or Contact.in_combat(c.state.figures, f) or f.spell_effects.has("blinding_light"):
		return empty
	if not available_spell(f, id):
		return empty
	if id == "wizard_eye":
		return eye.options(f)
	if id == "crumble":
		return crumble.options(f)
	if id in ["power_word", "draining_word"]:
		return WordMagic.options(c.state, f, id)
	return weapons.options(f) if id == "decay" else counter.options(f)


func start_counter(id: String, index: int) -> bool:
	var options := counter_options(id)
	if index < 0 or index >= options.size():
		return false
	var option := options[index]
	return _roll(id, option["target"], null, false, -1, option)


func treasure_options(id: String) -> Array[TreasureToken]:
	var out: Array[TreasureToken] = []
	var f := c.state.active()
	if id not in ["telekinesis", "fools_gold"] or f == null or not c.can_act() or f.def.role not in ["wizard", "apprentice"] or Contact.in_combat(c.state.figures, f) or f.spell_effects.has("blinding_light") or not available_spell(f, id):
		return out
	for token in c.state.treasures:
		if treasure_magic.can_target(f, id, token) and not treasure_magic.points(f, id, token, true).is_empty():
			out.append(token)
	return out


func start_treasure(id: String, token_id: int, at: Vector2) -> bool:
	var token := c.state.treasure(token_id)
	if token == null or not treasure_options(id).has(token) or not treasure_magic.can_place(c.state.active(), id, token, at):
		return false
	return _roll(id, c.state.active_id, at, false, -1, {"token": token_id})


func start_move(id: String, target_id: int, at: Vector2) -> bool:
	if not can_cast(id, target_id):
		return false
	var f := c.state.active()
	var t := c.state.figure(target_id)
	if id == "leap":
		if not movement.can_land(f, t, id, at):
			return false
	elif id == "suggestion":
		if not suggestion_points(t).has(at):
			return false
	else:
		return false
	return _roll(id, target_id, at)


func suggestion_points(t: Figure) -> Array[Vector2]:
	var out: Array[Vector2] = [t.pos]
	var center := MovePlanner.node_at(t.pos)
	for dx in range(-6, 7):
		for dy in range(-6, 7):
			var at := MoveGrid.to_pos(center + Vector2i(dx, dy))
			if Vector2(t.pos.distance_to(at), t.elevation - c.state.board.height_at(at)).length() <= 3.0 and ElevationRules.fall_damage(t.elevation - c.state.board.height_at(at)) == 0 and movement.landing(t, at):
				if not out.has(at):
					out.append(at)
	return out


func start_swap(first: int, second: int) -> bool:
	if not can_cast("transpose", first) or not can_cast("transpose", second) or not movement.can_swap(c.state.active(), c.state.figure(first), c.state.figure(second)):
		return false
	return _roll("transpose", first, null, false, second)


func placement_points(id: String, first_only: bool = false, rotated: bool = false) -> Array[Vector2]:
	var f := c.state.active()
	var empty: Array[Vector2] = []
	if not c.state.board.floor_layout.is_empty():
		return empty
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
	if shatter.eligible(f, c.state, id):
		var declared := shatter.declare(f, id, target_id, at, rotated, second, effect)
		if declared.is_empty():
			return false
		_dispatch_shatter(declared)
		advance_shatter()
		return true
	return _authorize_roll(id, target_id, at, rotated, second, effect)


func _authorize_roll(id: String, target_id: int, at: Variant, rotated: bool, second: int, effect: Dictionary) -> bool:
	var f := c.state.active()
	var targets: Array[Figure] = [c.state.figure(target_id)]
	if second >= 0:
		targets.append(c.state.figure(second))
	if id in ["elemental_bolt", "bone_dart", "poison_dart"]:
		targets.assign(ShotTarget.participants(c.state.figures, targets[0]))
	beauty.authorize(f, targets, _roll_authorized.bind(id, target_id, at, rotated, second, effect))
	return true


func _roll_authorized(id: String, target_id: int, at: Variant, rotated: bool, second: int, effect: Dictionary) -> void:
	var f := c.state.active()
	if f == null or not f.in_play():
		return
	illusions.reveal(f)
	var known: bool = c.state.spellbooks.get(f.side, {}).has(id)
	var scroll := not known and ScrollActions.consume(f, id)
	var raw := 14 if scroll else c.dice.d20()
	var gear_bonus := ActiveGear.casting_bonus(f, id)
	if not scroll and f.next_cast_gear == "gear_gloves_casting" and ActiveGear.spend(f, f.next_cast_gear):
		gear_bonus += 5
	elif not scroll and f.next_cast_gear == "gear_wand_light" and ActiveGear.spend(f, f.next_cast_gear):
		var alternate := c.dice.d20()
		c.emit("wand_roll", {"id": f.id, "first": raw, "second": alternate})
		raw = maxi(raw, alternate)
	f.next_cast_gear = ""
	var plane_penalty := PlaneWalk.penalty(f, c.state.turn) if id == "plane_walk" else 0
	if id == "plane_walk":
		PlaneWalk.record(f, c.state.turn)
	var empowered := not scroll and f.spell_effects.erase("potion_empowerment")
	var total := 14 if scroll else CastingRoll.modified(raw, gear_bonus + (4 if empowered else 0) + plane_penalty + RealityCracks.casting_modifier(c.state,id) + RedKingSinkhole.casting_modifier(c.state,f) + f.roll_penalty() + WordMagic.modifier(c.state, id) + BaseRules.casting_bonus(f.campaign_base, id) - (2 if f.spell_effects.has("furious_quill") else 0) - (2 if f.affected_by_insects() else 0), f.def.role == "apprentice")
	var tn := int(c.state.spellbooks.get(f.side, {}).get(id, c.state.spell_catalog[id]["number"]))
	if not shatter.spent:
		c._spend(f)
		if not shatter.next.is_empty() or shatter.resolving:
			shatter.spent = true
	c.state.pending_cast = {"id": id, "caster": f.id, "target": target_id, "raw": raw, "total": total, "tn": tn, "scroll": scroll, "cordial": empowered}
	if at != null:
		c.state.pending_cast["at"] = at
		c.state.pending_cast["rotated"] = rotated
	c.state.pending_cast["second"] = second
	if not effect.is_empty():
		c.state.pending_cast["effect"] = effect
	c.emit("cast_roll", c.state.pending_cast.duplicate())
	if id in ["spell_eater", "strike_dead"]:
		c._hurt(f, 1, f, false)
	if RealityCracks.id(c.state)==7 and RealityCracks.casting_modifier(c.state,id)==5:
		c._hurt(f,2,f,false)


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
	shatter.resolving = true
	var ok := _finish_one(health)
	shatter.resolving = false
	if ok:
		advance_shatter()
	return ok


func _finish_one(health: int) -> bool:
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
	if MagicEquipment.bonus(f,"cast_failure_cap")>0:
		result["failure_damage"]=mini(int(result["failure_damage"]),1)
	c._hurt(f, hp + int(result["failure_damage"]) + (2 if p.get("cordial", false) else 0), f, false)
	c.emit("cast_result", {"id": f.id, "spell": id, "target": t.id, "success": result["success"], "roll": result["roll"], "spent": hp, "power": power, "tn": p["tn"], "failure_damage": result["failure_damage"], "scroll": p.get("scroll", false)})
	if id == "summon_demon" and int(p["raw"]) == 1 and not p.get("scroll", false):
		summons.miscast_demon(f)
		return true
	if not result["success"]:
		return true
	RedKingGear.charge(f,str(s.spell_catalog[id].get("school","")))
	if id in ["dispel", "spell_eater"]:
		counter.apply(p["effect"])
		return true
	if id in ["power_word", "draining_word"]:
		WordMagic.apply(s, f, id, p["effect"]["chosen"])
		c.emit("spell_effect", {"id": f.id, "spell": id})
		return true
	if id == "wizard_eye":
		eye.create(f, p["effect"])
		return true
	if id == "crumble":
		crumble.apply(p["effect"]["piece"])
		return true
	if id == "decay":
		weapons.destroy(t, p["effect"]["weapon"])
		return true
	if id in ["telekinesis", "fools_gold"]:
		treasure_magic.apply(f, id, s.treasure(p["effect"]["token"]), p["at"], int(result["roll"]))
		return true
	if id=="bridge" and p.get("effect",{}).has("layered_bridge"):
		LayeredBridge.apply(c,p["effect"]["layered_bridge"])
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
	if id in ["heal","mind_lock","elemental_shield","blinding_light","petrify","bones_of_the_earth","slow","curse","furious_quill","plague_of_insects","strike_dead","steal_health","suggestion","blink"]:
		t=CreatureEffects.reflection_target(c,f,t,id)
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
			if p.get("effect",{}).has("floor_destination"):
				if id=="leap":
					LayeredLeap.apply(c,t,p["effect"])
				else:
					LayeredMagic.apply_teleport(c,t,p["effect"])
			else:
				movement.move(t, p["at"], true)
		"suggestion":
			resistance.attempt(t, int(result["roll"]), _suggestion_result.bind(t, p["at"]),5 if t.def.traits.has("blood_marked") else 0)
			return true
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
			t=CreatureEffects.reflection_target(c,f,t,id)
			var old_health := t.health
			_shot(f, t, int(s.spell_catalog[id]["power"]), WizardEye.origin(s.board, f, t.pos, float(s.spell_catalog[id].get("range", 24.0))), id == "elemental_bolt", id == "elemental_bolt", id)
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
				if other.in_play() and other.ring_side==f.ring_side and not ScenarioNull.muted(other) and other.is_demon() and Shooting.distance(f, other) <= 24.0 and LineOfSight.check(s.board, f.pos, other.pos).clear:
					_banish(f, other, int(result["roll"])+MagicEquipment.bonus(f,"banish_resistance_tn"), 4)
		"scatter_shot":
			for other in s.figures:
				if other.in_play() and other.ring_side==f.ring_side and other.side != f.side and Shooting.distance(f, other) <= 12 and LineOfSight.check(s.board, f.pos, other.pos).clear:
					_shot(f, CreatureEffects.reflection_target(c,f,ShotTarget.randomize(c.dice,s.figures,other),id), 0, f.pos, false, true, id)
		"destructive_sphere":
			for other in s.figures:
				if other != f and other.in_play() and other.ring_side==f.ring_side and Shooting.distance(f, other) <= 3:
					_direct_attack(f, CreatureEffects.reflection_target(c,f,other,id), 5)
		"plane_walk":
			c._loot.drop_on_death(f)
			f.spell_effects[id] = true
			f.spell_effects.erase("bones_of_the_earth")
		"beauty":
			t.spell_effects[id] = int(result["roll"])
		"bones_of_the_earth":
			t.spell_effects[id] = true
		"possess":
			t.spell_effects[id] = f.id
		"slow", "curse", "furious_quill", "plague_of_insects":
			t.spell_effects[id] = int(result["roll"])
			if id == "slow" and t == s.active():
				t.actions_left = 0
		"elemental_ball":
			var affected: Array[Figure] = []
			for other in s.figures:
				if other.in_play() and other.ring_side==t.ring_side and Shooting.distance(t, other) <= 1.0 and (other == t or LineOfSight.check(s.board, t.pos, other.pos).clear):
					for member in ShotTarget.participants(s.figures, other):
						if not affected.has(member):
							affected.append(member)
			for other in affected:
				var recipient := CreatureEffects.reflection_target(c,f,other,id)
				_shot(f, recipient, 5, f.pos if recipient==f or other==t else t.pos, true, true, id)
		"destroy_undead":
			var raw := c.dice.d20()
			var total := raw + t.effective_will() + t.roll_penalty()
			if not StatRoll.succeeds(raw, t.effective_will() + t.roll_penalty(), result["roll"]):
				c._hurt(t, t.health if t.effective_will() <= 2 else maxi(0, int(result["roll"]) - total) * 3, f, false)
		"strike_dead":
			resistance.attempt(t, int(result["roll"]), _resisted_death.bind(f, t), 0, true)
			return true
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


func _shot(f: Figure, t: Figure, power: int, origin: Variant = null, elemental: bool = false, magical: bool = true, spell: String = "") -> void:
	if f.ring_side!=t.ring_side or (RedKingTethers.pylon(t) and not magical) or not t.in_play() or t.spell_effects.has("plane_walk") or ScenarioNull.muted(t) or (magical and t.def.traits.has("antithetical_magic")):
		return
	var s := c.state
	var from: Vector2 = WizardEye.origin(s.board, f, t.pos) if origin == null else origin
	var los := LineOfSight.check(s.board, from, t.pos,f) if s.board.floor_layout.is_empty() else LineOfSight.check_figures(s.board,f,t)
	if not los.clear and (not s.board.floor_layout.is_empty() or RedKingHill.cracked(s)):
		return
	var mod := Shooting.target_mod(los) + (1 if f.moves_taken > 0 else 0)
	if t.def.traits.has("large"):
		mod -= 2
	var ar := c.dice.d20()
	var dr := c.dice.d20()
	var a := ar - (2 if RealityCracks.low_gravity(f) else 0) + mini(power + (3 if t.spell_effects.has("glow") else 0), 10) + f.roll_penalty()
	var d := dr + mini(t.effective_fight() + mod, 10) + t.roll_penalty() + t.shooting_defence_penalty()
	var won := a > d
	if s.critical_hits:
		won = dr != 20 and (ar == 20 or won)
	var dmg := Damage.amount(a, 0, t.effective_armour() + (CreatureEffects.elemental_resistance(t) if elemental else 0), ar, s.critical_hits and not t.def.traits.has("immune_critical")) if won else 0
	if not magical and t.def.traits.has("immune_normal"):
		dmg = 0
	if elemental and MagicEquipment.bonus(t, "absorb") > 0:
		dmg = ceili(dmg / 2.0)
	if elemental:
		dmg = PotionActions.absorb(t, dmg)
	c.emit("spell_shot", {"id": f.id, "target": t.id, "attack": a, "defence": d, "spell": spell, "origin": from if s.board.floor_layout.is_empty() else null})
	var old_health := t.health
	c._hurt(t, dmg, f)
	if t.health<old_health:
		RedKingHill.balance(c,t)


func _resist_effect(f: Figure, id: String) -> void:
	if f.in_play() and f.spell_effects.has(id) and StatRoll.succeeds(c.dice.d20(), f.effective_will() + f.roll_penalty(), int(f.spell_effects[id])):
		f.spell_effects.erase(id)
		c.emit("spell_expired", {"id": f.id, "spell": id})


func on_activate(f: Figure) -> void:
	if f.spell_effects.has("potion_invulnerability") and c.dice.d20() >= 17:
		f.spell_effects.erase("potion_invulnerability")
		c.emit("spell_expired", {"id": f.id, "spell": "potion_invulnerability"})
	_resist_effect(f, "furious_quill")


func on_end_activation(f: Figure) -> void:
	shatter.clear()
	f.spell_effects.erase("potion_shatterstar")
	f.next_cast_gear = ""
	f.spell_effects.erase("potion_fire_breath")
	f.spell_effects.erase("potion_burrowing")
	f.petrified_skip = false
	_resist_effect(f, "slow")
	_resist_effect(f, "plague_of_insects")
	if f.in_play() and f.control_spell == "mind_control" and StatRoll.succeeds(c.dice.d20(), f.effective_will() + f.roll_penalty(), f.control_roll):
		summons.release(f)


func on_end_turn() -> void:
	if not c.state.board.floor_layout.is_empty():
		LayeredBridge.expire(c)
	terrain.expire()
	for f in c.state.figures:
		if f.spell_effects.erase("plane_walk"):
			c.emit("spell_expired", {"id": f.id, "spell": "plane_walk"})
		_resist_effect(f, "curse")
		_resist_effect(f, "blinding_light")


func _banish(f: Figure, t: Figure, roll: int, threshold: int) -> void:
	t=CreatureEffects.reflection_target(c,f,t,"banish")
	var raw := c.dice.d20()
	var will := t.effective_will() + t.roll_penalty()
	if not StatRoll.succeeds(raw, will, roll):
		c._hurt(t, t.health if t.effective_will() <= threshold else maxi(0, roll - raw - will) * 3, f, false)


func _direct_attack(f: Figure, t: Figure, power: int) -> void:
	if ScenarioNull.muted(t) or t.def.traits.has("antithetical_magic"):
		return
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
	if ScenarioNull.muted(f):
		return false
	if id in ["summon_demon", "control_demon"]:
		for t in c.state.figures:
			if t.in_play() and t.prepared_demon_caster == f.id:
				return false
	return c.state.spellbooks.get(f.side, {}).has(id) or ScrollActions.has_scroll(f, id)


func available_spells(f: Figure) -> Array[String]:
	var out: Array[String] = []
	if ScenarioNull.muted(f):
		return out
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


func _resisted_death(success: bool, f: Figure, t: Figure) -> void:
	if not success and t.in_play():
		c._hurt(t, t.health, f, false)


func _suggestion_result(success: bool, t: Figure, at: Vector2) -> void:
	if success or not t.in_play():
		return
	c._loot.drop_on_death(t)
	if at != t.pos:
		movement.move(t, at)


func reroll_fate() -> bool:
	var p := c.state.pending_cast
	if p.is_empty() or p.get("scroll", false):
		return false
	var f := c.state.figure(p["caster"])
	if not ActiveGear.spend(f, "gear_fate_stone"):
		return false
	var old := int(p["raw"])
	var raw := c.dice.d20()
	p["raw"] = raw
	p["total"] = int(p["total"]) + raw - old
	c.emit("fate_reroll", {"id": f.id, "first": old, "second": raw})
	return true


func _dispatch_shatter(entry: Dictionary) -> void:
	var f := c.state.active()
	if f == null or not f.in_play() or f.id != int(entry["caster"]):
		return
	var t := c.state.figure(entry["target"])
	if t == null or not t.in_play():
		return
	if entry["second"] >= 0 and not c.state.figure(entry["second"]).in_play():
		return
	_authorize_roll(entry["id"], entry["target"], entry["at"], entry["rotated"], entry["second"], entry["effect"])


func advance_shatter() -> void:
	if shatter.resolving or not c.state.pending_cast.is_empty() or c.awaiting_reaction():
		return
	if not shatter.next.is_empty():
		var entry := shatter.next
		shatter.next = {}
		shatter.resolving = true
		_dispatch_shatter(entry)
		shatter.resolving = false
	if c.state.pending_cast.is_empty() and not c.awaiting_reaction():
		shatter.spent = false


func single_shatter() -> bool:
	if shatter.first.is_empty():
		return false
	var entry := shatter.first
	shatter.first = {}
	var f := c.state.active()
	if f == null or not f.in_play() or f.id != int(entry["caster"]):
		return false
	f.spell_effects.erase("potion_shatterstar")
	_dispatch_shatter(entry)
	return true
