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
		if not Contact.touching(o.pos, enemy.pos):
			continue
		if Contact.enemies_of(figures, o).size() == 1:
			bonus += SUPPORT
	return bonus


static func fight_mod(figures: Array[Figure], f: Figure, enemy: Figure) -> int:
	var net := clampi(support(figures, f, enemy) - support(figures, enemy, f), 0, 6)
	return mini(f.effective_fight() + f.melee.fight_mod + net, 10)


## Rolls the fight. Returns {a_roll, b_roll, a_total, b_total, a_dmg, b_dmg}:
## damage each side takes (a_dmg is dealt to `a`).
## TODO(rules): the winner's option to push the loser back is not modelled.
static func resolve(dice: Dice, figures: Array[Figure], a: Figure, b: Figure, critical_hits: bool = false) -> Dictionary:
	var ar := dice.d20()
	var br := dice.d20()
	var at := ar + fight_mod(figures, a, b)
	var bt := br + fight_mod(figures, b, a)
	var out := {"a_roll": ar, "b_roll": br, "a_total": at, "b_total": bt, "a_dmg": 0, "b_dmg": 0}
	var ac := critical_hits and ar == 20
	var bc := critical_hits and br == 20
	if ac or (not bc and at >= bt):
		out["b_dmg"] = Damage.amount(at, a.melee.damage_mod + b.melee.enemy_damage_mod, b.effective_armour(), ar, critical_hits)
	if bc or (not ac and bt >= at):
		out["a_dmg"] = Damage.amount(bt, b.melee.damage_mod + a.melee.enemy_damage_mod, a.effective_armour(), br, critical_hits)
	out["winner"] = a.id if (ac and not bc) or (not ac and not bc and at > bt) else (b.id if (bc and not ac) or (not ac and not bc and bt > at) else -1)
	return out
