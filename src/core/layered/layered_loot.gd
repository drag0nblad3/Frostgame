class_name LayeredLoot
extends RefCounted


static func exit_nodes(c: GameController) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	var f := c.state.active()
	if f==null or f.side<0 or f.control_spell=="mind_control" or FuryRules.target(c.state,f)!=null:
		return out
	var layout := c.state.board.floor_geometry()
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
	var layout := c.state.board.floor_geometry()
	if n!=layout.node(f.surface_id,f.pos):
		return LayeredMovement.move(c,n,false,false,false,true)
	c.spend_move(f)
	complete(c,f)
	return true


static func complete(c: GameController,f: Figure) -> void:
	var layout:=c.state.board.floor_geometry()
	if f.in_play() and is_exit(c.state,layout,layout.node(f.surface_id,f.pos)) and not Contact.in_combat(c.state.figures,f):
		c._loot.complete_exit(f)
