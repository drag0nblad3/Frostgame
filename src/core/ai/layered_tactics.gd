class_name LayeredTactics
extends RefCounted
## Evaluate shortcuts to actual treasure/contact objectives. No spell can
## bypass the controller's placement, action, sight or null-field checks.


static func loot_nodes(s: GameState,layout: FloorLayout,grid: LayeredGrid) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	for t in s.treasures:
		if not t.on_ground() or t.frozen:
			continue
		var center := layout.node(t.surface_id,t.pos)
		if center.z<0:
			continue
		for dx in range(-1,2):
			for dy in range(-1,2):
				var n := center+Vector3i(dx,dy,0)
				if grid.open(n) and layout.point(n).distance_to(t.pos)<=Figure.BASE_RADIUS+TreasureRules.TOKEN_RADIUS+0.01:
					out.append(n)
	return out


static func shortcut(c: GameController,f: Figure,layout: FloorLayout,reach: LayeredReach,long_route: LayeredReach,grid: LayeredGrid,goal: Variant) -> bool:
	if f.treasure_id>=0 or goal==reach.start:
		return false
	var walk_cost: float = long_route.cost.get(goal,INF)
	if walk_cost<=MoveRules.allowance(f)+0.001:
		return false
	# Running jumps are attractive only when they actually reach the
	# objective floor and improve distance without taking falling damage.
	var jumps := LayeredJump.plans(c)
	var best_jump: Variant = null
	var best_score := INF
	for n: Vector3i in jumps:
		if goal==null or n.z!=goal.z or ElevationRules.fall_damage(float(jumps[n]["fall"]))>0:
			continue
		var score := layout.world(n).distance_to(layout.world(goal))+float(jumps[n]["cost"])
		if score<walk_cost-1.0 and score<best_score:
			best_score=score
			best_jump=n
	if best_jump!=null and c.jump_on_floor(best_jump):
		return true
	if not CasterLoadout.is_caster(f.def.role) or not c.can_act() or ScenarioNull.muted(f) or f.health<=3:
		return false
	if LayeredBridgeTactics.try_cast(c,f,layout,long_route,grid):
		return true
	var candidates := loot_nodes(c.state,layout,grid)
	var best: Variant = null
	var gain := 3.0
	for n in candidates:
		var saved: float = long_route.cost.get(n,100.0)-MoveRules.allowance(f)
		if saved<=gain or reach.can_reach(n) or not LayeredMagic.can_teleport(c,n):
			continue
		best=n
		gain=saved
	if best!=null and c.teleport_on_floor(best):
		return resolve(c)
	# Leap a friendly soldier to a token if its ordinary move cannot get
	# there. A landed target cannot pick up until the next turn.
	for t in c.state.figures:
		if t==f or t.activated or t.magic_exhausted or t.treasure_id>=0 or not LayeredLeap.eligible(c,t):
			continue
		var target_grid := LayeredGrid.new(layout,t,c.state.figures)
		var start := layout.node(t.surface_id,t.pos)
		var normal := LayeredReach.search(target_grid,start,MoveRules.allowance(t))
		for n in loot_nodes(c.state,layout,target_grid):
			if normal.can_reach(n) or layout.world(start).distance_to(layout.world(n))<MoveRules.allowance(t)+1.0:
				continue
			if c.leap_on_floor(t.id,n):
				return resolve(c)
	return false


static func resolve(c: GameController) -> bool:
	return MagicBot.resolve(c)
