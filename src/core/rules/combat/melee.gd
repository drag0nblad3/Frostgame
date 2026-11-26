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
		if o == f or not o.in_play() or o.side != f.side:
			continue
		if not Contact.figures_touch(o, enemy):
			continue
		if Contact.enemies_of(figures, o).size() == 1:
			bonus += SUPPORT
	return bonus


static func fight_mod(figures: Array[Figure], f: Figure, enemy: Figure) -> int:
	var net := clampi(support(figures, f, enemy) - support(figures, enemy, f), 0, 6)
	return mini(f.effective_fight() + f.melee.fight_mod + net + (1 if f.spell_effects.has("enchant_weapon") and f.ranged == null else 0), 10)


## Rolls the fight. Returns {a_roll, b_roll, a_total, b_total, a_dmg, b_dmg}:
## damage each side takes (a_dmg is dealt to `a`).
## TODO(rules): the winner's option to push the loser back is not modelled.
static func resolve(dice: Dice, figures: Array[Figure], a: Figure, b: Figure, critical_hits: bool = false) -> Dictionary:
	var ar := dice.d20()
	var br := dice.d20()
	var at := ar + fight_mod(figures, a, b) + a.roll_penalty()
	var bt := br + fight_mod(figures, b, a) + b.roll_penalty()
	var out := {"a_roll": ar, "b_roll": br, "a_total": at, "b_total": bt, "a_dmg": 0, "b_dmg": 0}
	var ac := critical_hits and ar == 20
	var bc := critical_hits and br == 20
	if ac or (not bc and at >= bt):
		out["b_dmg"] = _damage(at, a, b, ar, critical_hits)
	if bc or (not ac and bt >= at):
		out["a_dmg"] = _damage(bt, b, a, br, critical_hits)
	out["winner"] = a.id if (ac and not bc) or (not ac and not bc and at > bt) else (b.id if (bc and not ac) or (not ac and not bc and bt > at) else -1)
	return out


static func _damage(total: int, winner: Figure, loser: Figure, natural: int, critical_hits: bool) -> int:
	var extra := 2 if winner.def.traits.has("strong") else 0
	var dmg := Damage.amount(total, winner.melee.damage_mod + loser.melee.enemy_damage_mod + extra, loser.effective_armour(), natural, false)
	if winner.def.traits.has("powerful"):
		dmg *= 2
	if critical_hits and natural == 20:
		dmg += 5
	if dmg > 0 and winner.ranged == null and winner.spell_effects.has("elemental_hammer"):
		dmg += 5
	return dmg
