class_name LayeredBattleBot
extends RefCounted
## Small battle AI. Plans with the full floor graph, then executes legal
## controller moves. Selective shortcuts use the same action validators.


static func play(c: GameController) -> bool:
	if c.state.over:
		return false
	var f := c.state.active()
	if f==null:
		var options := c.activatable()
		if options.is_empty() or not c.activate(options[0].id):
			return false
		f=c.state.active()
	if not c.awaiting_reaction() and not c.state.pending_cast.is_empty():
		MagicBot.resolve(c)
	if not c.awaiting_reaction() and _cape(c,f):
		if c.state.active()!=f or c.awaiting_reaction():
			return true
	for i in 2:
		if not f.in_play() or f.actions_left<=0 or c.awaiting_reaction():
			break
		if _act(c,f):
			continue
		if not _move(c,f):
			break
	if c.awaiting_reaction() or c.state.active()!=f:
		return true
	if c.state.push_winner>=0:
		if not c.resolve_push(c.state.figure(c.state.push_winner).treasure_id>=0):
			c.stay_in_combat()
	c.end_activation()
	return true


static func _act(c: GameController,f: Figure) -> bool:
	for enemy in c.state.figures:
		if c.can_fight(enemy.id):
			c.fight(enemy.id)
			return true
	for token in c.state.treasures:
		if c.can_pick_up(token.id):
			return c.pick_up(token.id)
	# Treasure seekers prioritize movement; missile units may take a shot.
	if f.treasure_id<0 and f.ranged!=null:
		if c.can_reload():
			return c.reload()
		for enemy in c.state.figures:
			if c.can_shoot(enemy.id,false,true):
				return c.shoot(enemy.id,false,true)
			if c.can_shoot(enemy.id):
				return c.shoot(enemy.id)
	return false


static func _move(c: GameController,f: Figure) -> bool:
	var layout := FloorLayout.from_dict(c.state.board.floor_layout)
	var reach := c.layered_reach()
	if reach.cost.is_empty():
		return false
	if f.treasure_id>=0:
		var exits := c.floor_exit_nodes()
		if not exits.is_empty():
			return c.exit_on_floor(exits[0])
	var grid := LayeredGrid.new(layout,f,c.state.figures)
	var long_route := LayeredReach.search(grid,reach.start,100.0)
	var goal: Variant = null
	var best := INF
	for n: Vector3i in long_route.cost:
		var distance: float = long_route.cost[n]
		if distance>=best:
			continue
		if f.treasure_id>=0:
			if LayeredLoot.is_exit(c.state,layout,n):
				goal=n
				best=distance
		else:
			for token in c.state.treasures:
				if token.on_ground() and token.surface_id==layout.surface_id(n) and token.pos.distance_to(layout.point(n))<=0.8:
					goal=n
					best=distance
	# When every remaining token is carried, seek enemy contact instead.
	if goal==null or goal==reach.start:
		best=INF
		for n: Vector3i in long_route.cost:
			var distance: float = long_route.cost[n]
			if distance>=best or n==reach.start:
				continue
			for enemy in c.state.figures:
				if enemy.in_play() and enemy.side!=f.side and absf(enemy.elevation-layout.height(n))<0.5 and Contact.touching(enemy.pos,layout.point(n)):
					best=distance
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


static func _cape(c: GameController,f: Figure) -> bool:
	if not GearActions.cape_ready(c) or (f.treasure_id<0 and f.health>4 and f.def.role not in ["wizard","apprentice"]):
		return false
	var layout := FloorLayout.from_dict(c.state.board.floor_layout)
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
