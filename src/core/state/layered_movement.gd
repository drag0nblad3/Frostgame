class_name LayeredMovement
extends RefCounted
## Controller-owned experimental movement for ordinary figures.
## Until reactions and magic are migrated, reject those cases rather than silently skip them.


static func eligible(c: GameController) -> bool:
	var s := c.state
	var f := s.active()
	if s.board.floor_layout.is_empty() or not c.can_move() or f.surface_id.is_empty():
		return false
	if s.forced_combat or not s.scenario_special.is_empty() or s.group.in_progress() or FuryRules.target(s,f)!=null:
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


static func reach(c: GameController) -> LayeredReach:
	if not eligible(c):
		return LayeredReach.new()
	var s := c.state
	var f := s.active()
	var layout := FloorLayout.from_dict(s.board.floor_layout)
	if not layout.errors.is_empty():
		return LayeredReach.new()
	var start := layout.node(f.surface_id,f.pos)
	if not layout.standable(start) or not layout.point(start).is_equal_approx(f.pos) or not is_equal_approx(layout.height(start),f.elevation):
		return LayeredReach.new()
	return LayeredReach.search(LayeredGrid.new(layout,f,s.figures),start,MoveRules.allowance(f))


static func move(c: GameController,node: Vector3i) -> bool:
	var reachable := reach(c)
	if node==reachable.start or not reachable.can_reach(node):
		return false
	var f := c.state.active()
	var layout := FloorLayout.from_dict(c.state.board.floor_layout)
	var path := PackedVector3Array()
	var surfaces: Array[String] = []
	for step in reachable.path_to(node):
		path.append(layout.world(step))
		surfaces.append(layout.surface_id(step))
	f.spell_effects.erase("petrify")
	f.actions_left-=1
	f.moves_taken+=1
	f.pos=layout.point(node)
	f.elevation=layout.height(node)
	f.surface_id=layout.surface_id(node)
	c.emit("layered_move",{"id":f.id,"path":path,"surfaces":surfaces,"cost":float(reachable.cost[node])})
	return true
