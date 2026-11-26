class_name CreatureBot
extends RefCounted
## Basic uncontrolled-creature priorities (pp. 69–70).

static func play(c: GameController, f: Figure) -> void:
	for i in 2:
		if not f.in_play() or f.actions_left <= 0:
			return
		var enemy := BotTargets.weakest_contact(c.state, f)
		if enemy != null:
			if c.can_act():
				c.fight(enemy.id)
			return
		var target: Figure = null
		for t in c.state.figures:
			if t.side < 0 or not t.in_play() or not LineOfSight.check(c.state.board, f.pos, t.pos).clear:
				continue
			if target == null or f.pos.distance_to(t.pos) < f.pos.distance_to(target.pos):
				target = t
		if target != null and f.ranged != null:
			if c.can_shoot(target.id):
				c.shoot(target.id)
			elif c.can_reload():
				c.reload()
			return
		if not c.can_move():
			return
		var r := c.reach()
		var node: Variant = null
		if target != null:
			node = BotTargets.advance_node(c.state, f, r, target)
		elif i == 0:
			var direction := Vector2.RIGHT.rotated(TAU * c.dice.pick(20) / 20.0)
			var grid := MoveGrid.new(c.state.board, f, c.state.figures)
			for step in range(1, int(MoveRules.allowance(f) / MoveGrid.STEP) + 1):
				var n := MovePlanner.node_at(f.pos + direction * step * MoveGrid.STEP)
				if not r.can_reach(n) or not grid.open(n):
					break
				node = n
				if grid.stops(n):
					break
		if node == null or MoveGrid.to_pos(node).distance_to(f.pos) < 0.01:
			return
		c.move_to(node)
