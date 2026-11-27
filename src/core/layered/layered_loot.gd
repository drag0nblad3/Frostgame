class_name LayeredLoot
extends RefCounted


static func exit_nodes(c: GameController) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	var f := c.state.active()
	if f==null or f.side<0 or f.control_spell=="mind_control":
		return out
	var layout := FloorLayout.from_dict(c.state.board.floor_layout)
	var r := c.layered_reach()
	for n: Vector3i in r.cost:
		if is_exit(c.state,layout,n) and float(r.cost[n])+Figure.BASE_RADIUS<=MoveRules.allowance(f)+0.001:
			var blocked := false
			for enemy in c.state.figures:
				if enemy.in_play() and enemy.side!=f.side and absf(enemy.elevation-layout.height(n))<0.5 and Contact.touching(enemy.pos,layout.point(n)):
					blocked=true
					break
			if not blocked:
				out.append(n)
	return out


static func is_exit(s: GameState,layout: FloorLayout,n: Vector3i) -> bool:
	if not layout.standable(n):
		return false
	# Only authored extraction surfaces may lead off the table.
	var allowed: Array = s.board.floor_layout.get("exit_surfaces",["street"])
	return allowed.has(layout.surface_id(n)) and TreasureRules.edge_distance(s.board,layout.point(n))<=Figure.BASE_RADIUS+0.01


static func exit(c: GameController,n: Vector3i) -> bool:
	if not exit_nodes(c).has(n):
		return false
	var f := c.state.active()
	var layout := FloorLayout.from_dict(c.state.board.floor_layout)
	if n!=layout.node(f.surface_id,f.pos):
		if not c.move_on_floor(n):
			return false
	else:
		f.moves_taken+=1
		f.actions_left-=1
	for id in f.carried_treasures():
		c._loot.secure(c.state.treasure(id),f.side)
	f.exited=true
	c._magic.summons.enforce_illusion_limit(f)
	f.actions_left=0
	c.emit("exit",{"id":f.id})
	return true
