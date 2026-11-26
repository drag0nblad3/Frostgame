class_name LayeredSight
extends RefCounted
## True 3D slab intersection (x/z footprint and vertical interval).
## The same geometry blocks walking clearance and shots.


static func clear(layout: FloorLayout,a: Vector3,b: Vector3) -> bool:
	for solid in layout.solids:
		if intersects(a,b,solid):
			return false
	return true


static func intersects(a: Vector3,b: Vector3,solid: AABB) -> bool:
	var footprint := Rect2(solid.position.x,solid.position.z,solid.size.x,solid.size.z)
	var interval := Geom.clip(Vector2(a.x,a.z),Vector2(b.x,b.z),footprint)
	if interval.size()!=2:
		return false
	var lo := minf(lerpf(a.y,b.y,interval[0]),lerpf(a.y,b.y,interval[1]))
	var hi := maxf(lerpf(a.y,b.y,interval[0]),lerpf(a.y,b.y,interval[1]))
	return hi>=solid.position.y and lo<=solid.end.y


static func figures_clear(layout: FloorLayout,a: Figure,b: Figure) -> bool:
	return clear(layout,Vector3(a.pos.x,a.elevation+1.5,a.pos.y),Vector3(b.pos.x,b.elevation+1.0,b.pos.y))
