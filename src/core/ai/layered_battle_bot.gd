class_name LayeredBattleBot
extends RefCounted
## Small battle AI. Plans with the full floor graph, then executes legal
## controller moves. Selective shortcuts use the same action validators.


## Compatibility entry point. Activation selection, pending casts and
## end-of-activation bookkeeping are owned by Bot for every geometry.
static func play(c: GameController) -> bool:
	return Bot.play_activation(c) if c.state.active()==null else Bot.resume_activation(c)


static func perform(c: GameController,f: Figure) -> void:
	if f.side<0 and (RedKingInvestigations.dormant(c.state,f) or RedKingSquatter.dormant(c,f) or ScenarioGenie.flee(c,f)):
		return
	if not c.awaiting_reaction() and _cape(c,f):
		if c.state.active()!=f or c.awaiting_reaction():
			return
	for i in 2:
		if c.state.active()!=f or not f.in_play() or f.actions_left<=0 or c.awaiting_reaction():
			break
		if not c.state.pending_cast.is_empty():
			break
		if _act(c,f):
			continue
		if not _move(c,f):
			break


static func _act(c: GameController,f: Figure) -> bool:
	var enemy := CreatureBot.weakest(c.state,f) if f.side<0 else BotTargets.weakest_contact(c.state,f)
	if enemy!=null and c.can_fight(enemy.id):
		if f.side<0:
			PackRules.remember(c.state,f,enemy)
		return c.fight(enemy.id)
	if f.side>=0 and c.can_drink_well():
		return c.drink_well()
	if f.side>=0 and c.break_ice():
		return true
	if f.side>=0 and not f.def.traits.has("animal"):
		for token in c.state.treasures:
			if c.can_pick_up(token.id):
				return c.pick_up(token.id)
	if f.side<0 and f.def.traits.has("elemental_blast") and c.can_act() and not f.spell_effects.has("blinding_light"):
		var shot := CreatureBot._blast_target(c,f)
		if shot!=null:
			c._spend(f)
			c._magic._shot(f,shot,3,Vector3(f.pos.x,f.elevation+1.5,f.pos.y),true,true,"elemental_blast")
			return true
	if MagicBot.play(c,f):
		return true
	if f.treasure_id<0 and f.ranged!=null:
		if c.can_reload():
			return c.reload()
		var target := CreatureBot.closest(c,f,true) if f.side<0 else BotTargets.best_legal_shot(c,f)
		if f.side>=0 and RedKingBot.special_shot(c,f,target):
			return true
		if target!=null and c.can_shoot(target.id):
			return c.shoot(target.id,false,c.can_shoot(target.id,false,true))
	return false


static func _move(c: GameController,f: Figure) -> bool:
	var layout := c.state.board.floor_geometry()
	var reach := c.layered_reach()
	if reach.cost.is_empty():
		return false
	var extracting:=f.treasure_id>=0 or (f.side>=0 and RedKingInvestigations.active(c.state) and not RedKingInvestigations.has_objectives(c.state))
	if extracting:
		var exits := c.floor_exit_nodes()
		if not exits.is_empty():
			return c.exit_on_floor(exits[0])
	var quarry: Figure=null
	if f.side<0:
		quarry=PackRules.pursuit(c.state,f)
		if quarry==null:
			quarry=CreatureBot.closest(c,f)
		PackRules.remember(c.state,f,quarry)
		if quarry==null:
			return _wander(c,f,layout,reach)
	var grid := LayeredGrid.new(layout,f,c.state.figures)
	var column:=ScenarioColumns.contact(c.state.board,f.pos,f.elevation)
	if column!=null and f.side>=0 and f.treasure_id<0:
		for n: Vector3i in reach.cost:
			if n!=reach.start and ScenarioColumns.contact(c.state.board,layout.point(n),layout.height(n))==column:
				return c.move_on_floor(n)
	var long_route := LayeredReach.search(grid,reach.start,100.0,column!=null)
	var goal: Variant = null
	var best := INF
	for n: Vector3i in long_route.cost:
		var distance: float = long_route.cost[n]
		if distance>=best:
			continue
		if extracting:
			if LayeredLoot.is_exit(c.state,layout,n,f.side):
				goal=n
				best=distance
		elif f.side>=0 and not f.def.traits.has("animal"):
			for token in c.state.treasures:
				if not token.on_ground() or token.ring_side!=f.ring_side or token.surface_id!=layout.surface_id(n):
					continue
				if token.frozen and c.state.scenario_special=="complex_temple":
					var guardian:=ScenarioColumns.contact(c.state.board,layout.point(n),layout.height(n))
					if guardian==null or guardian.rect.get_center().distance_to(token.pos)>0.01:
						continue
				elif token.pos.distance_to(layout.point(n))>0.8:
					continue
				goal=n
				best=distance
	# When not extracting or pursuing a reachable objective, seek a legal
	# firing position rather than forcing every shooter into melee.
	if f.treasure_id<0 and (goal==null or goal==reach.start) and f.ranged!=null and f.actions_left>=2 and c.can_act() and (not f.ranged.needs_reload or f.loaded):
		var spot: Variant=_shooting_spot(c,f,layout,reach)
		if spot!=null:
			return c.move_on_floor(spot)
	if goal==null or goal==reach.start:
		best=INF
		for n: Vector3i in long_route.cost:
			var distance: float = long_route.cost[n]
			if distance>=best or n==reach.start:
				continue
			for enemy in c.state.figures:
				if not enemy.in_play() or enemy.side==f.side or enemy.ring_side!=f.ring_side or WormRider.ignored(f,enemy) or RingworldBot.protected_key(c.state,f,enemy):
					continue
				if (quarry!=null and enemy!=quarry) or (quarry==null and not IllusionRules.visible_to(c.state.figures,f,enemy)):
					continue
				if Contact.touches_position(enemy,layout.point(n),layout.height(n),layout.surface_id(n)):
					var score:=distance+float(enemy.health)*0.25+(0.0 if BotTargets.can_harm(f,enemy,f.melee) else 20.0)
					if score<best:
						best=score
						goal=n
	if f.treasure_id>=0 and goal!=null and RunForIt.ready(c,true):
		var run := LayeredMovement.reach(c,false,true,true)
		var route := long_route.path_to(goal)
		for i in range(route.size()-1,0,-1):
			if reach.can_reach(route[i]):
				break
			if run.can_reach(route[i]) and LayeredMovement.move(c,route[i],false,true,true):
				return true
	if LayeredTactics.shortcut(c,f,layout,reach,long_route,grid,goal):
		return true
	if goal==null or goal==reach.start:
		return false
	var path := long_route.path_to(goal)
	for i in range(path.size()-1,0,-1):
		if reach.can_reach(path[i]):
			return c.move_on_floor(path[i])
	return false


## Reuse the same range, physical sight and damageability score as flat AI.
static func _shooting_spot(c: GameController,f: Figure,layout: FloorLayout,reach: LayeredReach) -> Variant:
	var best: Variant=null
	var value:=0.0
	var enemies: Array[Figure]=[]
	for enemy in c.state.figures:
		if enemy.in_play() and enemy.side!=f.side and enemy.ring_side==f.ring_side and (f.side>=0 or enemy.side>=0) and not RingworldBot.protected_key(c.state,f,enemy) and BotTargets.can_harm(f,enemy,f.ranged):
			enemies.append(enemy)
	for node: Vector3i in reach.cost:
		if node==reach.start or not MovementContact.enemies_at(c.state.figures,f,layout.point(node),layout.height(node),layout.surface_id(node)).is_empty():
			continue
		var point:=layout.world(node)
		for enemy in enemies:
			if not Shooting.possible_from_world(c.state.board,c.state.figures,f,point,enemy):
				continue
			var score:=BotTargets.shot_value_world(c.state,f,point,enemy)-float(reach.cost[node])*0.01
			if score>value:
				best=node
				value=score
	return best


static func _wander(c: GameController,f: Figure,layout: FloorLayout,reach: LayeredReach) -> bool:
	if f.moves_taken>0:
		return false
	var heading:=PackRules.heading(c,f)
	var best: Variant=null
	var value:=0.0
	for node: Vector3i in reach.cost:
		var progress:=heading.dot(layout.point(node)-f.pos)
		if progress>value:
			best=node
			value=progress
	return best!=null and c.move_on_floor(best)


static func _cape(c: GameController,f: Figure) -> bool:
	if not GearActions.cape_ready(c) or (f.treasure_id<0 and f.health>4 and f.def.role not in ["wizard","apprentice"]):
		return false
	var layout := c.state.board.floor_geometry()
	var reach := LayeredMovement.reach(c,true)
	var best: Variant=null
	var value := 0.0
	for node: Vector3i in reach.cost:
		if node==reach.start:
			continue
		var position := layout.world(node)
		var distance := 6.0
		for other in c.state.figures:
			if other.in_play() and other.side!=f.side:
				distance=minf(distance,position.distance_to(Vector3(other.pos.x,other.elevation,other.pos.y)))
		var score := distance-float(reach.cost[node])*0.05
		if distance>=3.0 and score>value:
			value=score
			best=node
	return best!=null and LayeredMovement.move(c,best,true)
