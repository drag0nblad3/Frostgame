class_name TreasureBot
extends RefCounted
## Objective-first bot policy. Combat remains the fallback if no route is usable.

static func play(c: GameController, f: Figure) -> bool:
	if RedKingInvestigations.active(c.state) and not RedKingInvestigations.has_objectives(c.state) and not Contact.in_combat(c.state.figures,f):
		return _escape(c,f)
	if c.state.treasures.is_empty() or Contact.in_combat(c.state.figures, f):
		return false
	if f.def.traits.has("animal"):
		return false
	var acted := false
	for i in 2:
		if not f.in_play() or f.actions_left == 0:
			break
		if f.treasure_id >= 0:
			if not _escape(c, f):
				break
			acted = true
			continue
		# Collect an available token before spending time evaluating other routes.
		var collected := false
		for token in c.state.treasures:
			if c.can_pick_up(token.id) and c.pick_up(token.id):
				acted = true
				collected = true
				break
		if collected:
			continue
		var target := _nearest(c, f)
		if target == null:
			break
		if target.frozen and c.state.scenario_special == "complex_temple" and ScenarioColumns.contact(c.state.board, f.pos) != null and c.can_move():
			# Move around the column to make contact again after a failed fight.
			var reach := c.reach()
			var moved := false
			for node: Vector2i in reach.nodes():
				var at := MoveGrid.to_pos(node)
				if at.distance_to(f.pos) > 0.1 and ScenarioColumns.contact(c.state.board, at) == ScenarioColumns.contact(c.state.board, f.pos):
					moved = c.move_to(node)
					if moved:
						break
			if moved:
				acted = true
				continue
		if target.frozen and c.break_ice():
			acted = true
			continue
		if c.pick_up(target.id):
			acted = true
			continue
		if not c.can_move():
			break
		var r := c.reach()
		var field := MovePlanner.distance_field(c.state.board, target.pos)
		var best: Variant = null
		var score: float = field.get(MovePlanner.node_at(f.pos), INF)
		for n: Vector2i in r.nodes():
			var value: float = field.get(n, INF)
			if value < score - 0.05:
				best = n
				score = value
		if best == null or not c.move_to(best):
			break
		acted = true
	if Contact.in_combat(c.state.figures, f) and c.can_act():
		var enemy := BotTargets.weakest_contact(c.state, f)
		if enemy != null:
			c.fight(enemy.id)
			acted = true
	return acted


static func _nearest(c: GameController, f: Figure) -> TreasureToken:
	var best: TreasureToken = null
	var distance := INF
	for token in c.state.treasures:
		if not token.on_ground():
			continue
		var field := MovePlanner.distance_field(c.state.board, token.pos)
		var route: float = field.get(MovePlanner.node_at(f.pos), INF)
		if not is_finite(route):
			continue
		var d := route + (3.0 if token.frozen else 0.0)
		for ally in c.state.side_figures(f.side):
			if ally != f and ally.treasure_id < 0 and not ally.def.traits.has("animal") and float(field.get(MovePlanner.node_at(ally.pos), INF)) + 2.0 < route:
				d += 2.0
		for enemy in c.state.figures:
			if not enemy.in_play() or enemy.side == f.side or enemy.spell_effects.has("plane_walk"):
				continue
			if Vector3(enemy.pos.x, enemy.elevation, enemy.pos.y).distance_to(Vector3(token.pos.x, c.state.board.height_at(token.pos), token.pos.y)) <= Figure.BASE_RADIUS + TreasureRules.TOKEN_RADIUS + 1.0:
				d += 4.0 if BotTargets.can_harm(f, enemy, f.melee) else 14.0
		if d < distance:
			distance = d
			best = token
	return best


static func _escape(c: GameController, f: Figure) -> bool:
	if not c.can_move():
		return false
	var r := c.reach()
	var best: Variant = null
	var field := MovePlanner.exit_field(c.state,f.side)
	var score: float = field.get(MovePlanner.node_at(f.pos), INF)
	for n: Vector2i in r.nodes():
		var at := MoveGrid.to_pos(n)
		var d: float = field.get(n, INF)
		if TreasureRules.edge_distance(c.state.board, at) <= Figure.BASE_RADIUS + 0.01 and r.cost[n] + Figure.BASE_RADIUS <= MoveRules.allowance(f) + 0.001:
			if c.exit_table(n):
				return true
		if d < score - 0.05:
			best = n
			score = d
	return best != null and c.move_to(best)
