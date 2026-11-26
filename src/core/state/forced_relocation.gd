class_name ForcedRelocation
extends RefCounted
## Find a nearby legal landing without tracing a walking path.
## Standard (single exposed surface) battlefields only.
static func destination(s: GameState,f: Figure,desired: Vector2) -> Vector2:
	var b := s.board
	var margin := Vector2.ONE*Figure.BASE_RADIUS
	var target := desired.clamp(margin,b.size-margin)
	var grid := MoveGrid.new(b,f,s.figures)
	var center := MovePlanner.node_at(target)
	# Search adjacent half-inch lattice positions in order of actual distance.
	var best := f.pos
	var best_distance := INF
	for radius in range(0,13):
		for x in range(-radius,radius+1):
			for y in range(-radius,radius+1):
				if maxi(absi(x),absi(y))!=radius:
					continue
				var node := center+Vector2i(x,y)
				var at := MoveGrid.to_pos(node)
				var distance := at.distance_squared_to(target)
				if distance<best_distance and grid.open(node):
					best=at
					best_distance=distance
		if best_distance<INF and sqrt(best_distance)<float(radius)*MoveGrid.STEP:
			break
	return best


static func relocate(c: GameController,f: Figure,desired: Vector2) -> bool:
	if not f.in_play() or not c.state.board.floor_layout.is_empty():
		return false
	var at := destination(c.state,f,desired)
	if RedKingVeil.touch(c,f,at):
		return true
	if at.is_equal_approx(f.pos):
		return false
	var old := f.pos
	f.pos=at
	f.elevation=c.state.board.height_at(at)
	f.disengaged.clear()
	for other in c.state.figures:
		other.disengaged.erase(f.id)
	c._displacement.clear()
	c.emit("forced_relocation",{"id":f.id,"from":old,"at":at,"height":f.elevation})
	return true
