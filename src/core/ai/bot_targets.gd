class_name BotTargets
extends RefCounted
## Target and position choices for the Bot. Reads state, never changes it.


## Enemy in contact with the lowest Health.
static func weakest_contact(s: GameState, f: Figure) -> Figure:
	var best: Figure = null
	for e in Contact.enemies_of(s.figures, f):
		if best == null or e.health < best.health:
			best = e
	return best


## Odds the shot beats the target's roll, from where the shooter stands.
static func shot_value(s: GameState, f: Figure, at: Vector2, t: Figure) -> float:
	var mod := Shooting.target_mod(LineOfSight.check(s.board, at, t.pos))
	var win := Dice.chance_win(f.def.shoot, t.def.fight + mod)
	return win * (1.0 + 4.0 / maxf(t.health, 1.0))


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
			if t.side == f.side or not t.in_play() or not IllusionRules.visible_to(s.figures, f, t) or not Contact.touching(at, t.pos):
				continue
			var score: float = t.health * 10.0 + r.cost[n]
			if score < best_score:
				best_score = score
				best = {"node": n, "target": t}
	return best


static func _touches_enemy(s: GameState, f: Figure, at: Vector2) -> bool:
	for t in s.figures:
		if t.side != f.side and t.in_play() and Contact.touching(at, t.pos):
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
