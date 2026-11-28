class_name SurfacePicker
extends RefCounted
## Analytic ray intersection with actual exposed surfaces.


static func pick(board: Board,origin: Vector3,direction: Vector3,ground_only: bool=false) -> Variant:
	var planes: Array[Plane] = [Plane(Vector3.UP,0.0)]
	for p in board.pieces:
		if (ground_only and not p.kind.ground_surface) or not (p.kind.walkable_top or p.kind.ground_surface):
			continue
		if p.ramp:
			var slope := (p.ramp_end-p.ramp_start)/(p.rect.size.y if p.ramp_rotated else p.rect.size.x)
			var normal := Vector3(0,1,-slope) if p.ramp_rotated else Vector3(-slope,1,0)
			planes.append(Plane(normal.normalized(),TableSpace.to_world(p.rect.position,p.ramp_start)))
		else:
			planes.append(Plane(Vector3.UP,p.surface_height(p.rect.position)))
	var best: Variant = null
	var distance := INF
	for plane in planes:
		var hit: Variant = plane.intersects_ray(origin,direction)
		if hit == null:
			continue
		var point := TableSpace.to_table(hit)
		if not board.contains(point) or absf((board.ground_height_at(point) if ground_only else board.height_at(point))-hit.y)>0.002:
			continue
		var d := origin.distance_to(hit)
		if d<distance:
			best = point
			distance = d
	return best
