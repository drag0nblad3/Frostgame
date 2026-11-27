class_name SpellAvailability
extends RefCounted
## Which spells a figure can cast now, their legal targets and placement points, and empowerment limits.


static func can_cast(sa: SpellActions, id: String, target_id: int,ammo: bool=false) -> bool:
	var s := sa.c.state
	if not s.board.floor_layout.is_empty() and not LayeredFigureSpells.SUPPORTED.has(id):
		return false
	var f := s.active()
	var t := s.figure(target_id)
	if not sa.c.can_act() or f == null or t == null or f.ring_side!=t.ring_side or not t.in_play() or RedKingMadMan.is_ryce(t) or ScenarioNull.muted(t) or t.def.traits.has("antithetical_magic"):
		return false
	if f.def.role not in ["wizard", "apprentice"] or Contact.in_combat(s.figures, f):
		return false
	if not sa.available_spell(f, id) or not s.spell_catalog.has(id):
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
			if Shooting.distance(f,t)>limit or (not LineOfSight.check(s.board,f.pos,t.pos).clear and TigerEye.witness(s.board,f,t.pos,limit)==null):
				return false
		elif not WizardEye.visible(s.board,f,t.pos,limit) and (kind=="touch" or TigerEye.witness(s.board,f,t.pos,limit)==null):
			return false
	if ammo:
		return id=="enchant_weapon" and t.side==f.side and MagicAmmo.can_enchant(t)
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
		return t != f and not t.mind_locked()
	if id == "bones_of_the_earth":
		return not t.def.traits.has("large") and t.elevation < 0.01 and not t.spell_effects.has(id)
	if id == "leap":
		return t.side == f.side and not t.spell_effects.has("bones_of_the_earth") and not t.spell_effects.has("petrify") and not sa.movement.points(f, t, id, true).is_empty()
	if id == "transpose":
		for other in s.figures:
			if sa.movement.can_swap(f, t, other):
				return true
		return false
	if id == "push":
		return t != f
	if id == "blink":
		return true
	if id == "enchant_armour":
		return t.def.role == "soldier" and t.def.armour >= 11 and not t.spell_effects.has(id)
	if SummonActions.CONTROL.has(id):
		return sa.summons.can_control(f, t, id)
	if id == "strike_dead":
		return t != f and not t.is_undead() and not t.def.traits.has("construct")
	if id == "destroy_undead":
		return t.is_undead()
	if kind in ["heal", "resist"] and (t.is_undead() or t.def.traits.has("construct")):
		return false
	if kind == "resist":
		return t.side != f.side
	if kind == "heal":
		return t.health < t.def.health
	return not t.spell_effects.has(id)


static func counter_options(sa: SpellActions, id: String) -> Array[Dictionary]:
	var f := sa.c.state.active()
	var empty: Array[Dictionary] = []
	if id not in ["dispel", "spell_eater", "decay", "power_word", "draining_word", "crumble", "wizard_eye"] or not sa.c.can_act() or f == null or f.def.role not in ["wizard", "apprentice"] or Contact.in_combat(sa.c.state.figures, f) or f.spell_effects.has("blinding_light"):
		return empty
	if not sa.available_spell(f, id):
		return empty
	if id == "wizard_eye":
		return sa.eye.options(f)
	if id == "crumble":
		return sa.crumble.options(f)
	if id in ["power_word", "draining_word"]:
		return WordMagic.options(sa.c.state, f, id)
	return sa.weapons.options(f) if id == "decay" else sa.counter.options(f)


static func treasure_options(sa: SpellActions, id: String) -> Array[TreasureToken]:
	var out: Array[TreasureToken] = []
	var f := sa.c.state.active()
	if id not in ["telekinesis", "fools_gold"] or f == null or not sa.c.can_act() or f.def.role not in ["wizard", "apprentice"] or Contact.in_combat(sa.c.state.figures, f) or f.spell_effects.has("blinding_light") or not sa.available_spell(f, id):
		return out
	for token in sa.c.state.treasures:
		if sa.treasure_magic.can_target(f, id, token) and not sa.treasure_magic.points(f, id, token, true).is_empty():
			out.append(token)
	return out


static func suggestion_points(sa: SpellActions, t: Figure) -> Array[Vector2]:
	var out: Array[Vector2] = [t.pos]
	var center := MovePlanner.node_at(t.pos)
	for dx in range(-6, 7):
		for dy in range(-6, 7):
			var at := MoveGrid.to_pos(center + Vector2i(dx, dy))
			if Vector2(t.pos.distance_to(at), t.elevation - sa.c.state.board.height_at(at)).length() <= 3.0 and ElevationRules.fall_damage(t.elevation - sa.c.state.board.height_at(at)) == 0 and sa.movement.landing(t, at):
				if not out.has(at):
					out.append(at)
	return out


static func placement_points(sa: SpellActions, id: String, first_only: bool = false, rotated: bool = false,extended: bool=false) -> Array[Vector2]:
	var f := sa.c.state.active()
	var empty: Array[Vector2] = []
	if not sa.c.state.board.floor_layout.is_empty():
		return empty
	if not sa.c.can_act() or f == null or f.def.role not in ["wizard", "apprentice"] or Contact.in_combat(sa.c.state.figures, f):
		return empty
	if not sa.available_spell(f, id) or not sa.is_placement(id):
		return empty
	if f.spell_effects.has("blinding_light") and id not in ["raise_zombie", "summon_demon", "illusionary_soldier"]:
		return empty
	if id == "teleport":
		return sa.movement.points(f, f, id, first_only)
	if TerrainMagic.SPELLS.has(id):
		return sa.terrain.points(f,id,rotated,first_only,extended)
	return sa.summons.points(f, id, first_only)


static func max_empowerment(sa: SpellActions) -> int:
	var p := sa.c.state.pending_cast
	if p.is_empty() or p.get("scroll", false):
		return 0
	var f := sa.c.state.figure(p["caster"])
	var resources := PowerPool.cast_resources(f,str(p["id"]))
	if p["id"] == "summon_demon":
		return 0 if int(p["raw"]) == 1 else resources
	return CastingRoll.max_empowerment(int(p["total"])+VampireStaff.amount(sa.c,p,true),resources)


static func available_spell(sa: SpellActions, f: Figure, id: String) -> bool:
	if ScenarioNull.muted(f) or CircletDefence.immune(f,id):
		return false
	if id in ["summon_demon", "control_demon"]:
		for t in sa.c.state.figures:
			if t.in_play() and t.prepared_demon_caster == f.id:
				return false
	return sa.c.state.spellbooks.get(f.side, {}).has(id) or ScrollActions.has_scroll(f, id)


static func available_spells(sa: SpellActions, f: Figure) -> Array[String]:
	var out: Array[String] = []
	if ScenarioNull.muted(f):
		return out
	for id: String in sa.c.state.spellbooks.get(f.side, {}):
		if not CircletDefence.immune(f,id):
			out.append(id)
	for item in f.items:
		var id := str(item.get("scroll", ""))
		if id != "" and not out.has(id) and not CircletDefence.immune(f,id):
			out.append(id)
	for id in ScrollShield.spells(f):
		if not out.has(id) and not CircletDefence.immune(f,id):
			out.append(id)
	return out
