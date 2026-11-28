class_name LayeredSight
extends RefCounted
## True 3D slab intersection (x/z footprint and vertical interval).
## The same geometry blocks walking clearance and shots.


static func clear(layout: FloorLayout,a: Vector3,b: Vector3) -> bool:
	if layout.profiled_ground!=null:
		var steps:=maxi(1,ceili(a.distance_to(b)*10.0))
		for i in range(steps+1):
			var at:=a.lerp(b,float(i)/steps)
			if at.y<layout.profiled_ground.height_at(Vector2(at.x,at.z))-0.002:
				return false
	for solid in layout.solids:
		if intersects(a,b,solid):
			return false
	for cylinder in layout.circular_solids:
		if intersects_cylinder(a,b,cylinder):
			return false
	for prism in layout.convex_solids:
		if prism.intersects_ray(a,b):
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


## Intersect the horizontal circle interval with the finite height interval.
static func intersects_cylinder(a: Vector3,b: Vector3,solid: AABB) -> bool:
	var center:=Vector2(solid.get_center().x,solid.get_center().z)
	var offset:=Vector2(a.x,a.z)-center
	var delta:=Vector2(b.x-a.x,b.z-a.z)
	var radius:=solid.size.x*0.5
	var q:=delta.length_squared()
	var lo:=0.0
	var hi:=1.0
	if q<=0.000001:
		if offset.length_squared()>radius*radius:
			return false
	else:
		var dot:=offset.dot(delta)
		var discriminant:=dot*dot-q*(offset.length_squared()-radius*radius)
		if discriminant<0.0:
			return false
		var root:=sqrt(discriminant)
		lo=maxf(lo,(-dot-root)/q)
		hi=minf(hi,(-dot+root)/q)
	if lo>hi:
		return false
	var bottom:=minf(lerpf(a.y,b.y,lo),lerpf(a.y,b.y,hi))
	var top:=maxf(lerpf(a.y,b.y,lo),lerpf(a.y,b.y,hi))
	return top>=solid.position.y and bottom<=solid.end.y
