class_name Melee
extends RefCounted
## Hand-to-hand fights: opposed d20 + Fight, the higher total deals damage.

## Bonus for each supporting friend.
const SUPPORT := 2


## +2 for each friend of `f` also touching `enemy` and not fighting anyone else.
## TODO(rules): confirm support rules (and whether a figure can support both sides).
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
	return f.def.fight + f.melee.fight_mod + support(figures, f, enemy)


## Rolls the fight. Returns {a_roll, b_roll, a_total, b_total, a_dmg, b_dmg}:
## damage each side takes (a_dmg is dealt to `a`).
## TODO(rules): on a tie we have both figures wound each other; check 2e.
## TODO(rules): the winner's option to push the loser back is not modelled.
static func resolve(dice: Dice, figures: Array[Figure], a: Figure, b: Figure) -> Dictionary:
	var ar := dice.d20()
	var br := dice.d20()
	var at := ar + fight_mod(figures, a, b)
	var bt := br + fight_mod(figures, b, a)
	var out := {"a_roll": ar, "b_roll": br, "a_total": at, "b_total": bt, "a_dmg": 0, "b_dmg": 0}
	if at >= bt:
		out["b_dmg"] = Damage.amount(at, a.melee.damage_mod + b.melee.enemy_damage_mod, b.def.armour, ar)
	if bt >= at:
		out["a_dmg"] = Damage.amount(bt, b.melee.damage_mod + a.melee.enemy_damage_mod, a.def.armour, br)
	return out
