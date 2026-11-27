class_name MagicTactics
extends RefCounted
## Heuristic tactical value, separate from spell legality.
const ATTACKS := ["elemental_bolt", "bone_dart", "poison_dart", "elemental_ball", "steal_health", "strike_dead", "destroy_undead"]
const HINDERS := ["slow", "curse", "blinding_light", "petrify", "furious_quill", "bones_of_the_earth", "glow", "plague_of_insects"]
const BUFFS := ["fleet_feet", "strength", "shield", "combat_awareness", "enchant_armour", "enchant_weapon", "elemental_hammer", "mind_lock", "invisibility", "possess", "beauty", "elemental_shield"]


static func importance(f: Figure) -> float:
	return 1.0 + (0.9 if f.treasure_id >= 0 else 0.0) + (0.5 if f.def.role in ["wizard", "apprentice"] else 0.0)


static func near_enemy(s: GameState, f: Figure) -> float:
	var dist := 30.0
	for t in s.figures:
		if t.in_play() and t.side != f.side:
			dist = minf(dist, Shooting.distance(f, t))
	return dist


static func probability(c: GameController, f: Figure, id: String) -> float:
	if not c.state.spellbooks.get(f.side, {}).has(id):
		return 1.0 if ScrollActions.has_scroll(f,id) or not ScrollShield.source(f,id).is_empty() else 0.0
	var tn := int(c.state.spellbooks[f.side][id])
	var mod := f.roll_penalty() + WordMagic.modifier(c.state, id) + BaseRules.casting_bonus(f.campaign_base, id) + ActiveGear.casting_bonus(f, id) + RealityCracks.casting_modifier(c.state,id) + RedKingSinkhole.casting_modifier(c.state,f)
	if f.def.role == "apprentice":
		mod -= 2
	return clampf((21.0 - tn + mod + mini(2, maxi(0, f.health - 2))) / 20.0, 0.05, 1.0)


static func value(c: GameController, f: Figure, t: Figure, id: String) -> float:
	var s := c.state
	var ally := t.side == f.side
	var threat := near_enemy(s, t)
	var priority := importance(t)
	var score := 0.0
	if id == "heal":
		if not ally or t.def.health - t.health < 3:
			return 0.0
		score = mini(5, t.def.health - t.health) * priority * (1.5 if t.health <= 5 else 1.0)
	elif id in SummonActions.CONTROL:
		if ally:
			return 0.0
		score = (5.0 + t.effective_fight() * 0.8 + t.health * 0.15) * priority
	elif id in ATTACKS:
		if ally:
			return 0.0
		if t.def.traits.has("immune_normal") and id in ["bone_dart", "poison_dart"]:
			return 0.0
		if id in ["elemental_ball", "elemental_bolt", "bone_dart", "poison_dart"]:
			for other in ShotTarget.participants(s.figures, t):
				if other.side == f.side:
					return 0.0
		score = (4.0 + 5.0 / maxf(t.health, 1.0)) * priority
		if t.def.traits.has("immune_normal"):
			score += 4.0
		if RedKingTethers.pylon(t) or RedKingRingworld.key_master(t):
			score+=6.0
		if t.def.traits.has("antithetical_magic") or t.def.traits.has("spell_reflection"):
			score*=0.45
		if id == "steal_health" and f.health < f.def.health:
			score += 2.0
		if id == "strike_dead":
			score += t.health * 0.35
	elif id in HINDERS:
		if ally:
			return 0.0
		score = (3.0 + t.effective_fight() * 0.25) * priority
		if id in ["slow", "bones_of_the_earth", "petrify"] and t.treasure_id >= 0:
			score += 4.0
	elif id in BUFFS:
		if not ally:
			return 0.0
		if id == "fleet_feet" or id == "invisibility":
			score = 7.0 if t.treasure_id >= 0 else (3.0 if threat < 8.0 else 1.0)
		elif id == "elemental_shield" or id == "beauty":
			score = 5.0 if threat < 9.0 else 1.0
		elif id == "mind_lock":
			score = 3.0 if threat < 12.0 else 0.0
		else:
			score = (4.0 if threat < 7.0 else 1.0) * priority
	elif id == "true_sight" and t == f:
		for enemy in s.figures:
			if enemy.in_play() and enemy.side != f.side and enemy.spell_effects.has("invisibility") and Shooting.distance(f, enemy) <= 6.0:
				score += 4.0
	else:
		return 0.0
	return score * probability(c, f, id)
