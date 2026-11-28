class_name LayeredFall
extends RefCounted
## Resolve a ledge descent onto the first supporting surface, not the lowest.
## If the first landing is occupied or blocked, reject rather than pass through it.


static func landing(layout: FloorLayout,grid: LayeredGrid,at: Vector2,above: float) -> Variant:
	var best: Variant = null
	var height := -INF
	for surface in layout.surfaces:
		if surface.id.begins_with("climb:"):
			continue
		var n := layout.node(surface.id,at)
		if not layout.contains(n) or surface.height_at(at)>=above-0.001:
			continue
		var h := layout.height(n)
		if h>height:
			height=h
			best=n
	if best==null or not grid.open(best):
		return null
	return best if clear_descent(layout,layout.world(best),above) else null

## Dropped treasure has its own physical radius and never occupies a hanging
## pseudo-surface. A crest may require a short slide off the wall before falling.
static func treasure_landing(s: GameState,at: Vector2,above: float) -> Variant:
	var layout:=s.board.floor_geometry()
	var center:=MovePlanner.node_at(at)
	var candidates: Array[Vector2i]=[center]
	for offset: Vector2i in MoveGrid.NEIGHBORS:
		candidates.append(center+offset)
	for offset: Vector2i in MoveGrid.NEIGHBORS:
		candidates.append(center+offset*2)
	candidates.sort_custom(func(a: Vector2i,b: Vector2i) -> bool:
		return MoveGrid.to_pos(a).distance_squared_to(at)<MoveGrid.to_pos(b).distance_squared_to(at))
	for point in candidates:
		var p:=MoveGrid.to_pos(point)
		if s.board.over_void(p,TreasureRules.TOKEN_RADIUS) or not s.board.contains(p,TreasureRules.TOKEN_RADIUS):
			continue
		var highest: Variant=null
		var height:=-INF
		for i in layout.surfaces.size():
			var deck:=layout.surfaces[i]
			if deck.id.begins_with("climb:"):
				continue
			var n:=Vector3i(point.x,point.y,i)
			if not layout.contains(n,TreasureRules.TOKEN_RADIUS):
				continue
			var h:=layout.height(n)
			if h<=above+0.001 and h>height:
				height=h
				highest=n
		if highest==null:
			continue
		var start:=Vector3(at.x,above,at.y)
		var edge:=Vector3(p.x,above,p.y)
		var finish:=layout.world(highest)
		var clear:=true
		for segment: Array in [[start,edge],[edge,finish]]:
			var a: Vector3=segment[0]
			var b: Vector3=segment[1]
			var steps:=maxi(1,ceili(a.distance_to(b)*10.0))
			for i in range(steps+1):
				if not layout.clearance(a.lerp(b,float(i)/steps),TreasureRules.TOKEN_RADIUS,0.5):
					clear=false
					break
			if not clear:
				break
		if clear:
			return highest
	return null


static func clear_descent(layout: FloorLayout,to: Vector3,above: float) -> bool:
	var steps := maxi(1,ceili((above-to.y)/0.1))
	for i in range(steps+1):
		var h := lerpf(above,to.y,float(i)/steps)
		if not layout.clearance(Vector3(to.x,h,to.z),Figure.BASE_RADIUS,1.6):
			return false
	return true


static func apply(c: GameController,f: Figure,distance: float,by: Figure) -> void:
	var damage := ElevationRules.fall_damage(distance-(3.0 if c.state.board.low_gravity else 0.0))
	if damage>0 and MagicEquipment.bonus(f,"slow_fall")==0 and not f.def.traits.has("levitate"):
		c._hurt(f,damage,by,false)
