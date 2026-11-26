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
	for i in 2:
		if not f.in_play() or f.actions_left<=0:
			break
		if _act(c,f):
			continue
		if not _move(c,f):
			break
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
	if LayeredTactics.shortcut(c,f,layout,reach,long_route,grid,goal):
		return true
	if goal==null or goal==reach.start:
		return false
	var path := long_route.path_to(goal)
	for i in range(path.size()-1,0,-1):
		if reach.can_reach(path[i]):
			return c.move_on_floor(path[i])
	return false
