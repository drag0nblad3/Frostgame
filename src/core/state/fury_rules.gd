class_name FuryRules
extends RefCounted


static func target(s: GameState, f: Figure) -> Figure:
	if f == null or not f.in_play() or not f.spell_effects.has("potion_fury"):
		return null
	var enemies := Contact.enemies_of(s.figures, f)
	if not enemies.is_empty():
		return enemies[0]
	var best: Figure = null
	for t in s.figures:
		if t.side == f.side or not t.in_play() or Contact.in_combat(s.figures, t) or BeautyActions.blocked(s, f, t) or not IllusionRules.visible_to(s.figures, f, t) or not LineOfSight.check(s.board, f.pos, t.pos).clear:
			continue
		if best == null or Shooting.distance(f, t) < Shooting.distance(f, best):
			best = t
	return best


static func restrict(s: GameState, f: Figure, r: MoveReach) -> MoveReach:
	var enemy := target(s, f)
	if enemy == null:
		return r
	var contact: Array[Vector2i] = []
	var advance: Array[Vector2i] = []
	var field := MovePlanner.distance_field(s.board, enemy.pos)
	var start: float = field.get(MovePlanner.node_at(f.pos), INF)
	for n: Vector2i in r.nodes():
		var at := MoveGrid.to_pos(n)
		if float(r.cost[n]) < 0.001:
			continue
		if absf(s.board.height_at(at) - enemy.elevation) < 0.5 and Contact.touching(at, enemy.pos):
			contact.append(n)
		elif float(field.get(n, INF)) < start - 0.01:
			advance.append(n)
	var legal := contact if not contact.is_empty() else advance
	# Keep predecessor links, since a legal route may cross unselectable nodes.
	for n: Vector2i in r.nodes():
		if not legal.has(n):
			r.cost.erase(n)
	return r


static func play(c: GameController, f: Figure) -> void:
	for i in 3:
		if c.awaiting_reaction() or not f.in_play() or f.actions_left <= 0:
			return
		for t in Contact.enemies_of(c.state.figures, f):
			if c.can_fight(t.id):
				c.fight(t.id)
				break
		if c.awaiting_reaction() or not f.in_play() or f.actions_left <= 0:
			return
		if not c.can_move():
			return
		var enemy := target(c.state, f)
		if enemy == null:
			return
		var r := c.reach()
		var best: Variant = null
		var score := INF
		for n: Vector2i in r.nodes():
			var distance := MoveGrid.to_pos(n).distance_to(enemy.pos)
			if distance < score:
				best = n
				score = distance
		if best == null or not c.move_to(best):
			return
