class_name Shooting
extends RefCounted
## Shooting: d20 + Shoot against the target's d20 + Fight + cover. Only the
## shooter can deal damage.

const LIGHT_COVER := 2
const HEAVY_COVER := 4
const INTERVENING := 1


## Range is measured base edge to base edge.
static func distance(a: Figure, b: Figure) -> float:
	return maxf(Vector3(a.pos.x, a.elevation, a.pos.y).distance_to(Vector3(b.pos.x, b.elevation, b.pos.y)) - 2.0 * Figure.BASE_RADIUS, 0.0)


## Why `shooter` can't shoot `target`, or "" if the shot is allowed.
static func blocked_reason(board: Board, figures: Array[Figure], shooter: Figure, target: Figure) -> String:
	if shooter.spell_effects.has("blinding_light"):
		return "blinded"
	if shooter.ranged == null:
		return "no missile weapon"
	if shooter.ranged.needs_reload and not shooter.loaded:
		return "needs to reload"
	if not target.in_play() or target == shooter or not IllusionRules.visible_to(figures, shooter, target):
		return "not a target"
	if target.side == shooter.side and not Contact.in_combat(figures, target):
		return "not an enemy"
	if Contact.in_combat(figures, shooter):
		return "in combat"
	if distance(shooter, target) > shooter.ranged.range_in:
		return "out of range"
	if not LineOfSight.check(board, shooter.pos, target.pos).clear:
		return "no line of sight"
	return ""


## Could `shooter` shoot `target` if it stood at `at`? (range, sight, target free)
static func possible_from(board: Board, figures: Array[Figure], shooter: Figure, at: Vector2, target: Figure) -> bool:
	if shooter.ranged == null or not IllusionRules.visible_to(figures, shooter, target) or Contact.in_combat(figures, target):
		return false
	if maxf(at.distance_to(target.pos) - 2.0 * Figure.BASE_RADIUS, 0.0) > shooter.ranged.range_in:
		return false
	return LineOfSight.check(board, at, target.pos).clear


## Bonus to the target's roll from terrain.
static func target_mod(los: LineOfSight.Result) -> int:
	var m := los.intervening * INTERVENING
	if los.cover == TerrainKind.Cover.HEAVY:
		m += HEAVY_COVER
	elif los.cover == TerrainKind.Cover.LIGHT:
		m += LIGHT_COVER
	return m


## Rolls the shot. Returns {s_roll, t_roll, s_total, t_total, mod, dmg}.
static func resolve(dice: Dice, board: Board, shooter: Figure, target: Figure, critical_hits: bool = false, storm_penalty: int = 0) -> Dictionary:
	return resolve_rolls(board, shooter, target, dice.d20(), dice.d20(), critical_hits, storm_penalty)


static func resolve_rolls(board: Board, shooter: Figure, target: Figure, sr: int, tr: int, critical_hits: bool = false, storm_penalty: int = 0) -> Dictionary:
	var los := LineOfSight.check(board, shooter.pos, target.pos)
	var mod := target_mod(los) + (1 if shooter.moves_taken > 0 else 0)
	if target.def.traits.has("large"):
		mod -= 2
	var st := sr + mini(shooter.effective_shoot() + MagicEquipment.bonus(shooter, "shoot", shooter.ranged.id) - storm_penalty + (1 if shooter.spell_effects.has("enchant_weapon") else 0) + (3 if target.spell_effects.has("glow") else 0), 10) + shooter.roll_penalty()
	var tt := tr + mini(target.effective_fight() + mod, 10) + target.roll_penalty() + target.shooting_defence_penalty()
	var dmg := 0
	if (not critical_hits and st > tt) or (critical_hits and tr != 20 and (sr == 20 or st > tt)):
		dmg = Damage.amount(st, shooter.ranged.damage_mod + MagicEquipment.bonus(shooter, "damage", shooter.ranged.id), target.effective_armour() + MagicEquipment.bonus(target, "arrow_armour"), sr, critical_hits)
		if dmg > 0 and shooter.spell_effects.has("elemental_hammer"):
			dmg += 5
	if (target.spell_effects.has("potion_invulnerability") or target.def.traits.has("immune_normal")) and not WeaponActions.magic_attack(shooter, shooter.ranged):
		dmg = 0
	return {"s_roll": sr, "t_roll": tr, "s_total": st, "t_total": tt, "mod": mod, "dmg": dmg}
