class_name LayeredMovement
extends RefCounted
## Controller-owned experimental movement for ordinary figures.
## Until reactions and magic are migrated, reject those cases rather than silently skip them.


static func eligible(c: GameController,cape: bool=false) -> bool:
	var s := c.state
	var f := s.active()
	if s.board.floor_layout.is_empty() or not (GearActions.cape_ready(c) if cape else c.can_move()) or f.surface_id.is_empty():
		return false
	if s.forced_combat or (not s.scenario_special.is_empty() and s.scenario_special!="silent_tower") or FuryRules.target(s,f)!=null:
		return false
	if f.spell_effects.has("plane_walk") or f.spell_effects.has("potion_burrowing") or f.def.traits.has("ethereal") or f.def.traits.has("burrowing"):
		return false
	for other in s.figures:
		if other.in_play() and (other.spell_effects.has("beauty") or other.spell_effects.has("invisibility") or IllusionRules.phantom(other)):
			return false
	for piece in s.board.pieces:
		if piece.cast_turn>=0:
			return false
	return true


static func reach(c: GameController,cape: bool=false,run: bool=false,boost: bool=false) -> LayeredReach:
	if not eligible(c,cape) or (run and not RunForIt.ready(c,boost)):
		return LayeredReach.new()
	var s := c.state
	var f := s.active()
	var layout := FloorLayout.from_dict(s.board.floor_layout)
	if not layout.errors.is_empty():
		return LayeredReach.new()
	var start := layout.node(f.surface_id,f.pos)
	if not layout.standable(start) or not layout.point(start).is_equal_approx(f.pos) or not is_equal_approx(layout.height(start),f.elevation):
		return LayeredReach.new()
	var grid := LayeredGrid.new(layout,f,s.figures)
	grid.running=run
	return LayeredReach.search(grid,start,(6.0 if boost else 3.0) if run else MoveRules.allowance(f),cape)


static func move(c: GameController,node: Vector3i,cape: bool=false,run: bool=false,boost: bool=false) -> bool:
	var reachable := reach(c,cape,run,boost)
	if node==reachable.start or not reachable.can_reach(node):
		return false
	var f := c.state.active()
	var engaged := Contact.in_combat(c.state.figures,f)
	if run and boost and not ActiveGear.spend(f,RunForIt.TALISMAN):
		return false
	if cape and not GearActions.use_cape(c,f):
		return false
	var layout := FloorLayout.from_dict(c.state.board.floor_layout)
	var path := PackedVector3Array()
	var surfaces: Array[String] = []
	for step in reachable.path_to(node):
		path.append(layout.world(step))
		surfaces.append(layout.surface_id(step))
	c.spend_move(f)
	# Maintain authoritative floor, elevation and position at every site
	# crossing; publish the movement chunk before its consequence.
	var chunk:=PackedVector3Array([path[0]])
	var chunk_surfaces: Array[String]=[surfaces[0]]
	var cost:=float(reachable.cost[node])
	for i in range(1,path.size()):
		var point:=path[i]
		f.pos=Vector2(point.x,point.z)
		f.elevation=point.y
		f.surface_id=surfaces[i]
		chunk.append(point)
		chunk_surfaces.append(surfaces[i])
		if ScenarioNull.field_at(c.state.board,f.pos):
			c.emit("layered_move",{"id":f.id,"path":chunk,"surfaces":chunk_surfaces,"cost":cost})
			chunk=PackedVector3Array([point])
			chunk_surfaces=[surfaces[i]]
			ScenarioNull.enter(c,f)
			if not f.in_play():
				c.finish_movement(f,engaged,false)
				if run:
					RunForIt.finish(c,f,boost)
				return true
	if chunk.size()>1:
		c.emit("layered_move",{"id":f.id,"path":chunk,"surfaces":chunk_surfaces,"cost":cost})
	c.finish_movement(f,engaged)
	if run:
		RunForIt.finish(c,f,boost)
	return true
