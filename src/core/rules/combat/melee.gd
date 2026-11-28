class_name Melee
extends RefCounted
## Hand-to-hand fights: opposed d20 + Fight, the higher total deals damage.

## Bonus for each supporting friend.
const SUPPORT := 2


## +2 for each friend of `f` also touching `enemy` and not fighting anyone else.
## Support eligibility and cancellation: Second Edition p. 53.
static func support(figures: Array[Figure], f: Figure, enemy: Figure) -> int:
	var bonus := 0
	for o in figures:
		if RuleHooks.any("objective_figure", [o]) or o == f or not o.in_play() or o.side != f.side or RuleHooks.any("no_support", [o]):
			continue
		if not Contact.figures_touch(o, enemy):
			continue
		if Contact.enemies_of(figures, o).size() == 1:
			bonus += maxi(0,SUPPORT-MagicEquipment.bonus(enemy,"support_reduction"))
	return bonus


static func fight_mod(figures: Array[Figure], f: Figure, enemy: Figure, charging: bool = false) -> int:
	if RuleHooks.any("objective_figure", [f]):
		return 0
	var net := clampi(support(figures, f, enemy) - support(figures, enemy, f), 0, 6)
	return mini(f.effective_fight() + Swimming.fight_penalty(f) + secret_hrut_bonus(f,enemy) + f.melee.fight_mod + MagicEquipment.bonus(f, "fight", f.melee.id) + net + (2 if charging and f.has_horns() else 0) + (1 if WeaponEnchantment.active(f,f.melee) else 0), 10)


## Rolls the fight. Returns {a_roll, b_roll, a_total, b_total, a_dmg, b_dmg}:
## damage each side takes (a_dmg is dealt to `a`).
## TODO(rules): the winner's option to push the loser back is not modelled.
static func resolve(dice: Dice, figures: Array[Figure], a: Figure, b: Figure, critical_hits: bool = false) -> Dictionary:
	return resolve_rolls(figures, a, b, dice.d20(), dice.d20(), critical_hits)


static func resolve_rolls(figures: Array[Figure], a: Figure, b: Figure, ar: int, br: int, critical_hits: bool = false) -> Dictionary:
	var at := ar + fight_mod(figures, a, b, a.moves_taken > 0) + a.roll_penalty()
	var bt := br + fight_mod(figures, b, a) + b.roll_penalty()
	var out := {"a_roll": ar, "b_roll": br, "a_total": at, "b_total": bt, "a_dmg": 0, "b_dmg": 0}
	var ac := critical_hits and ar == 20
	var bc := critical_hits and br == 20
	if ac or (not bc and at >= bt):
		var parts:=_damage_parts(at,a,b,ar,critical_hits)
		out["b_dmg"]=parts.x+parts.y
		out["b_hammer"]=parts.y
	if bc or (not ac and bt >= at):
		var parts:=_damage_parts(bt,b,a,br,critical_hits)
		out["a_dmg"]=parts.x+parts.y
		out["a_hammer"]=parts.y
	out["winner"] = a.id if (ac and not bc) or (not ac and not bc and at > bt) else (b.id if (bc and not ac) or (not ac and not bc and bt > at) else -1)
	return out


static func _damage(total: int,winner: Figure,loser: Figure,natural: int,critical_hits: bool) -> int:
	var parts:=_damage_parts(total,winner,loser,natural,critical_hits)
	return parts.x+parts.y


static func _damage_parts(total: int, winner: Figure, loser: Figure, natural: int, critical_hits: bool) -> Vector2i:
	if RuleHooks.any("objective_figure", [winner]):
		return Vector2i.ZERO
	if loser.def.traits.has("antithetical_magic") and WeaponActions.magic_attack(winner,winner.melee) and winner.melee.id=="natural":
		return Vector2i.ZERO
	var immune: bool=(loser.spell_effects.has("potion_invulnerability") or loser.def.traits.has("immune_normal")) and not WeaponActions.magic_attack(winner,winner.melee)
	var extra := (2 if winner.def.traits.has("strong") or winner.used_gear.get("rk_skull_strong",false) else 0) + (1 if winner.spell_effects.has("potion_fury") else 0)
	if loser.is_undead():
		extra += MagicEquipment.bonus(winner,"undead_damage")
	var dmg := Damage.amount(total, winner.melee.damage_mod + (2 if winner.melee.id=="unarmed" and winner.def.traits.has("blood_marked") else 0) + MagicEquipment.bonus(winner, "damage", winner.melee.id) + MagicEquipment.bonus(winner, "melee_damage") + loser.melee.enemy_damage_mod + extra, _armour(winner,loser), natural, false)
	if winner.def.traits.has("powerful") or (winner.def.traits.has("energy_drain") and MagicEquipment.bonus(loser,"energy_drain_immunity")==0 and not loser.is_undead() and not loser.def.traits.has("construct")):
		dmg *= 2
	if critical_hits and natural == 20 and not loser.def.traits.has("immune_critical"):
		dmg += 5
	var hammer:=5 if dmg>0 and WeaponEnchantment.active(winner,winner.melee,WeaponEnchantment.HAMMER) and not loser.def.traits.has("antithetical_magic") else 0
	if immune:
		return Vector2i(0,hammer)
	if dmg > 0 and natural != 1:
		dmg += RuleHooks.total("melee_damage_bonus", [winner, loser])
	return Vector2i(dmg,hammer)


## Expansion Fight bonuses against a particular enemy (rule hook "fight_bonus").
static func secret_hrut_bonus(f: Figure,enemy: Figure) -> int:
	return RuleHooks.total("fight_bonus", [f, enemy])


static func _armour(winner: Figure, loser: Figure) -> int:
	var override: Variant = RuleHooks.first("melee_armour", [winner, loser])
	return int(override) if override != null else loser.effective_armour()
