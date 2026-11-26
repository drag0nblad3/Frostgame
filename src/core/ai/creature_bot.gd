class_name CreatureBot
extends RefCounted
## Uncontrolled creatures prioritize combat, the closest visible warband
## member and finally random movement. A pack uses its leader's pursuit.

static func weakest(s: GameState, f: Figure) -> Figure:
	var target: Figure = null
	for enemy in Contact.enemies_of(s.figures, f):
		if target == null or enemy.health < target.health or (enemy.health == target.health and enemy.id < target.id):
			target = enemy
	return target


static func closest(c: GameController, f: Figure, shot: bool = false) -> Figure:
	var target: Figure = null
	for t in c.state.figures:
		if t.side < 0 or not t.in_play():
			continue
		var normal := IllusionRules.visible_to(c.state.figures,f,t) and LineOfSight.check_figures(c.state.board,f,t).clear
		if not normal and (shot or (not CreatureSenses.detects(f,t) and not RedKingSquatter.scent(c.state,f,t))):
			continue
		if shot and not c.can_shoot(t.id):
			continue
		if target == null or Shooting.distance(f, t) < Shooting.distance(f, target):
			target = t
	return target


static func play(c: GameController, f: Figure) -> void:
	if RedKingHill.is_herald(c.state,f):
		RedKingHill.play_herald(c,f)
		return
	if RedKingInvestigations.dormant(c.state,f):
		return
	if RedKingSquatter.dormant(c,f):
		return
	if ScenarioGenie.flee(c, f):
		return
	for i in 2:
		if not f.in_play() or f.actions_left <= 0 or c.awaiting_reaction():
			return
		var enemy := weakest(c.state, f)
		if enemy != null:
			if c.can_fight(enemy.id):
				PackRules.remember(c.state, f, enemy)
				c.fight(enemy.id)
			return
		var target := PackRules.pursuit(c.state, f)
		if target == null:
			target = closest(c, f)
		PackRules.remember(c.state, f, target)
		if f.def.traits.has("elemental_blast") and c.can_act() and not f.spell_effects.has("blinding_light"):
			var shot := _blast_target(c,f)
			if shot!=null:
				c._spend(f)
				c._magic._shot(f,shot,3,f.pos,true,true,"elemental_blast")
				continue
		if f.ranged != null:
			var shot := closest(c, f, true)
			if shot != null:
				c.shoot(shot.id)
				return
			if c.can_reload():
				c.reload()
				return
		if not c.can_move():
			return
		var r := c.reach()
		var node: Variant = null
		if target != null:
			node = BotTargets.advance_node(c.state, f, r, target)
		elif RedKingSquatter.active(c.state) and f.def.id=="blood_marked_berserker":
			var treasure: Variant=RedKingSquatter.treasure_target(c.state,f)
			if treasure!=null:
				node=RedKingSquatter.approach_treasure(c.state,f,r,treasure)
		elif i == 0 and f.moves_taken == 0:
			var direction := PackRules.heading(c, f)
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


static func _blast_target(c: GameController,f: Figure) -> Figure:
	var best: Figure=null
	for t in c.state.figures:
		if t.side<0 or not t.in_play() or not IllusionRules.visible_to(c.state.figures,f,t) or Shooting.distance(f,t)>24.0 or not LineOfSight.check_figures(c.state.board,f,t).clear:
			continue
		if best==null or Shooting.distance(f,t)<Shooting.distance(f,best):
			best=t
	return best
