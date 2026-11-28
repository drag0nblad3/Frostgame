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
	if best!=null and BattleSpellAction.execute(c,"place",{"spell":"teleport","at":best}):
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
			if BattleSpellAction.execute(c,"move",{"spell":"leap","target":t.id,"at":n}):
				return resolve(c)
	return false


static func resolve(c: GameController) -> bool:
	return MagicBot.resolve(c)


## Consider the same compound routes offered to the player, but only where
## an aerial shortcut is plausible. Compare progress with normal walking.
## This is deliberately a local heuristic, not an optimal multi-turn search.
static func aerial_progress(c: GameController,f: Figure,layout: FloorLayout,reach: LayeredReach,extracting: bool,quarry: Figure=null,shared_grid: LayeredGrid=null) -> bool:
	var s:=c.state
	if (f.side<0 and quarry==null) or reach.start.z<0 or PlaneWalk.uses_direct(f) or FuryRules.target(s,f)!=null or not reach.air_paths.is_empty():
		return false
	var support:=layout.surfaces[reach.start.z]
	var authored: bool=not s.board.floor_layout.get("jumps",[]).is_empty()
	var flat_street:=support.id=="street" and support.profiles.is_empty() and is_equal_approx(support.level,support.end_level)
	if flat_street and not authored and s.board.void_regions.is_empty():
		return false
	var origin:=layout.world(reach.start)
	var exits: Array[PackedVector3Array]=[]
	var objective: Variant=null
	if quarry!=null:
		objective=BattleSpace.center(quarry)
	elif extracting:
		exits=MagicBot._leap_exit_segments(s,layout,f.side)
		if exits.is_empty():
			return false
	else:
		var nearest:=INF
		if not f.def.traits.has("animal") and not RuleHooks.any("cannot_carry_treasure",[s,f]) and not BotPreference.prefers_combat(s,f):
			for token in s.treasures:
				if not token.on_ground() or token.ring_side!=f.ring_side:
					continue
				var height:=TreasureRules.token_height(s,token)
				if is_nan(height):
					continue
				var at:=Vector3(token.pos.x,height,token.pos.y)
				var score:=origin.distance_to(at)+BotPreference.variation(s,f,token.id,"aerial_loot")
				if score<nearest:
					nearest=score
					objective=at
		if objective==null:
			for enemy in s.figures:
				if not enemy.in_play() or enemy.side==f.side or enemy.ring_side!=f.ring_side or RingworldBot.protected_key(s,f,enemy) or WormRider.ignored(f,enemy) or (RedKingMadMan.hunter(f) and RedKingMadMan.is_ryce(enemy)) or not IllusionRules.visible_to(s.figures,f,enemy) or not BotTargets.can_harm(f,enemy,f.melee):
					continue
				var at:=BattleSpace.center(enemy)
				var score:=origin.distance_to(at)/BotPreference.threat_appeal(f,enemy)
				if score<nearest:
					nearest=score
					objective=at
	if objective==null and exits.is_empty():
		return false
	var distance:=func(at: Vector3) -> float:
		return MagicBot._leap_exit_distance(exits,at) if extracting and quarry==null else at.distance_to(objective)
	var initial:=float(distance.call(origin))
	var walking:=initial
	for n: Vector3i in reach.cost:
		if quarry!=null and Contact.touches_position(quarry,layout.point(n),layout.height(n),layout.surface_id(n)):
			return false
		walking=minf(walking,float(distance.call(layout.world(n))))
	# Do not interrupt ordinary movement that already reaches the objective.
	if quarry==null and (walking<=0.8 or initial<=1.5):
		return false
	var caution:=BotPreference.trait_value(f,"caution")
	var best_score:=initial-walking+0.65+0.6*caution
	var best: Variant=null
	var mode:=""
	var grid:=shared_grid if shared_grid!=null else LayeredGrid.new(layout,f,s.figures)
	grid.memoize_edges=true
	for kind: String in ["jump","drop_down"]:
		if kind=="drop_down" and flat_street:
			continue
		var budget:=BotPreference.aerial_budget(f)
		var plans:=LayeredJump.plans(c,true,true,grid,false,distance,budget) if kind=="jump" else LayeredDrop.plans(c,true,grid,reach,false,distance,budget)
		# Rank cheap geometry first, then sample a bounded shortlist; do not
		# lose every useful landing merely because a floor has many cells.
		var shortlist: Array[Dictionary]=[]
		for n: Vector3i in plans:
			var progress:=initial-float(distance.call(layout.world(n)))
			if progress>0.25:
				shortlist.append({"node":n,"progress":progress})
		shortlist.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:return a["progress"]>b["progress"])
		var top: Array=[]
		for i in mini(shortlist.size(),48):
			top.append(shortlist[i]["node"])
		for n: Vector3i in BotPreference.positions(s,f,top):
			var plan: Dictionary=plans[n]
			var damage:=aerial_damage(s,f,plan)
			if damage>=f.health or (damage>0 and (f.treasure_id>=0 or f.side<0)):
				continue
			var at:=layout.world(n)
			var progress:=initial-float(distance.call(at))
			var score:=progress*BotPreference.appeal(s,f,hash(n),"aerial")-float(damage)*(1.5+2.0*caution)-0.05*float(plan["cost"])
			if quarry!=null and Contact.touches_position(quarry,layout.point(n),layout.height(n),layout.surface_id(n)):
				score+=MoveRules.allowance(f)+2.0
			if score>best_score:
				best_score=score
				best=n
				mode=kind
	if best==null:
		return false
	# The full validator can find a cheaper route omitted by the shortlist.
	# Inspect that actual route before committing, particularly for carriers.
	var validated:=c.movement_options(mode)
	if not validated.jumps.has(best):
		return false
	var damage:=aerial_damage(s,f,validated.jumps[best])
	if damage>=f.health or (damage>0 and (f.treasure_id>=0 or f.side<0)):
		return false
	return BattleRecord.run(c,"movement",{"mode":mode,"node":best},func() -> bool:return LayeredMovement.declare_aerial(c,best,validated.jumps[best]))


static func aerial_damage(s: GameState,f: Figure,plan: Dictionary) -> int:
	var damage:=LayeredFall.damage(s,f,float(plan.get("fall",0.0)))
	if plan.has("next"):
		damage+=aerial_damage(s,f,plan["next"])
	return damage
