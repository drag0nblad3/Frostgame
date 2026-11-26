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


static func clear_descent(layout: FloorLayout,to: Vector3,above: float) -> bool:
	var steps := maxi(1,ceili((above-to.y)/0.1))
	for i in range(steps+1):
		var h := lerpf(above,to.y,float(i)/steps)
		if not layout.clearance(Vector3(to.x,h,to.z),Figure.BASE_RADIUS,1.6):
			return false
	return true


static func apply(c: GameController,f: Figure,distance: float,by: Figure) -> void:
	var damage := ElevationRules.fall_damage(distance)
	if damage>0 and MagicEquipment.bonus(f,"slow_fall")==0 and not f.def.traits.has("levitate"):
		c._hurt(f,damage,by,false)
