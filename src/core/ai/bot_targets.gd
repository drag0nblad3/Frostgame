class_name BotTargets
extends RefCounted
## Target and position choices for the Bot. Reads state, never changes it.


## Can a mundane/magical attack actually damage this target?
static func can_harm(f: Figure, t: Figure, weapon: WeaponDef) -> bool:
	if weapon == null or (RedKingMadMan.is_ryce(t) and (RedKingMadMan.hunter(f) or weapon.is_ranged())):
		return false
	if t.def.traits.has("immune_normal") or t.spell_effects.has("potion_invulnerability"):
		return not ScenarioNull.muted(t) and WeaponActions.magic_attack(f, weapon)
	return true


## Prefer opponents we can damage, then vulnerable high-value targets.
static func weakest_contact(s: GameState, f: Figure) -> Figure:
	var best: Figure = null
	for e in Contact.enemies_of(s.figures, f):
		if RedKingMadMan.hunter(f) and RedKingMadMan.is_ryce(e):
			continue
		var score := float(e.health) / MagicTactics.importance(e) + (0.0 if can_harm(f, e, f.melee) else 1000.0)
		var previous := INF if best == null else float(best.health) / MagicTactics.importance(best) + (0.0 if can_harm(f, best, f.melee) else 1000.0)
		if score < previous:
			best = e
	return best


## Odds the shot beats the target's roll, from where the shooter stands.
static func shot_value(s: GameState, f: Figure, at: Vector2, t: Figure) -> float:
	if not can_harm(f, t, f.ranged):
		return 0.0
	var mod := Shooting.target_mod(LineOfSight.check(s.board, at, t.pos))
	mod += 1 if f.moves_taken > 0 or at != f.pos else 0
	mod -= 2 if t.def.traits.has("large") else 0
	var attack := mini(10, f.effective_shoot() + MagicEquipment.bonus(f, "shoot", f.ranged.id) - s.storm_penalty + (3 if t.spell_effects.has("glow") else 0)) + f.roll_penalty()
	var defence := mini(10, t.effective_fight() + mod) + t.roll_penalty() + t.shooting_defence_penalty()
	var win := Dice.chance_win(attack, defence)
	return win * (1.0 + 4.0 / maxf(t.health, 1.0)) * MagicTactics.importance(t)


## Best enemy to shoot right now, or null.
static func best_shot(s: GameState, f: Figure) -> Figure:
	var best: Figure = null
	var best_v := 0.0
	for t in s.figures:
		if t.side == f.side or Contact.in_combat(s.figures, t) or Shooting.blocked_reason(s.board, s.figures, f, t) != "":
			continue
		var v := shot_value(s, f, f.pos, t)
		if v > best_v:
			best = t
			best_v = v
	return best


## Reachable node to shoot from, as {node, target}, or {} if none.
static func shooting_spot(s: GameState, f: Figure, r: MoveReach) -> Dictionary:
	var best := {}
	var best_v := 0.0
	for n: Vector2i in r.nodes():
		var at := MoveGrid.to_pos(n)
		if _touches_enemy(s, f, at):
			continue
		for t in s.figures:
			if t.side == f.side or not t.in_play():
				continue
			if not Shooting.possible_from(s.board, s.figures, f, at, t):
				continue
			var v: float = shot_value(s, f, at, t) - r.cost[n] * 0.01
			if v > best_v:
				best_v = v
				best = {"node": n, "target": t}
	return best


## Reachable node touching an enemy, as {node, target}; weakest enemy, then shortest move.
static func charge_spot(s: GameState, f: Figure, r: MoveReach) -> Dictionary:
	var best := {}
	var best_score := INF
	for n: Vector2i in r.nodes():
		var at := MoveGrid.to_pos(n)
		for t in s.figures:
			if t.side == f.side or not t.in_play() or not IllusionRules.visible_to(s.figures, f, t) or not Contact.touching(at, t.pos) or absf(s.board.height_at(at) - t.elevation) >= 0.5:
				continue
			var score: float = t.health * 10.0 + r.cost[n] + (0.0 if can_harm(f, t, f.melee) else 1000.0)
			if score < best_score:
				best_score = score
				best = {"node": n, "target": t}
	return best


static func _touches_enemy(s: GameState, f: Figure, at: Vector2) -> bool:
	for t in s.figures:
		if t.side != f.side and t.in_play() and absf(s.board.height_at(at) - t.elevation) < 0.5 and Contact.touching(at, t.pos):
			return true
	return false


static func nearest_enemy(s: GameState, f: Figure) -> Figure:
	var best: Figure = null
	for t in s.figures:
		if t.side != f.side and t.in_play() and IllusionRules.visible_to(s.figures, f, t):
			if best == null or f.pos.distance_to(t.pos) < f.pos.distance_to(best.pos):
				best = t
	return best


## Reachable node closest (by movement) to `target`, or the start if none is closer.
static func advance_node(s: GameState, f: Figure, r: MoveReach, target: Figure) -> Variant:
	var field := MovePlanner.distance_field(s.board, target.pos)
	var here: float = field.get(MovePlanner.node_at(f.pos), INF)
	var best: Variant = null
	var best_d := here
	for n: Vector2i in r.nodes():
		var d: float = field.get(n, INF)
		if d < best_d - 0.25:
			best_d = d
			best = n
	return best
