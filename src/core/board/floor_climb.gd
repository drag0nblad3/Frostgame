class_name FloorClimb
extends RefCounted
## A vertical route outside a wall, followed by a short step onto its top.
## One-inch intervals allow a figure to finish a move hanging on the wall.


static func add(layout: FloorLayout,d: Dictionary) -> void:
	var from: Array = d.get("from",[])
	var to: Array = d.get("to",[])
	var id := str(d.get("id",""))
	if id.is_empty() or from.size()!=3 or to.size()!=3:
		layout.errors.append("Malformed climb")
		return
	var a := layout.node(str(from[0]),Vector2(from[1],from[2]))
	var b := layout.node(str(to[0]),Vector2(to[1],to[2]))
	if not layout.standable(a) or not layout.standable(b) or layout.height(b)<=layout.height(a):
		layout.errors.append("Invalid climb "+id)
		return
	var start := layout.point(a)
	var low := layout.height(a)
	var high := layout.height(b)
	var count := ceili(high-low)
	if start.distance_to(layout.point(b))>1.5:
		layout.errors.append("Climb exit too far from wall "+id)
		return
	for i in range(1,count+1):
		var h := minf(high,low+float(i))
		var surface_id := "climb:"+id+":"+str(i)
		if layout.index_of(surface_id)>=0 or not layout.clearance(Vector3(start.x,h,start.y),Figure.BASE_RADIUS,1.6):
			layout.errors.append("Blocked or duplicate climb "+id)
			return
		var s := FloorSurface.new()
		s.id=surface_id
		s.rect=Rect2(start-Vector2.ONE*Figure.BASE_RADIUS,Vector2.ONE*Figure.BASE_RADIUS*2.0)
		s.level=h
		s.end_level=h
		layout.surfaces.append(s)
		var n := layout.node(s.id,start)
		# Reuse link validation, normal climbing costs and reverse direction.
		layout._add_link({"from":[layout.surface_id(a),layout.point(a).x,layout.point(a).y],"to":[s.id,start.x,start.y],"kind":"climb"})
		a=n
	layout._add_link({"from":[layout.surface_id(a),start.x,start.y],"to":[layout.surface_id(b),layout.point(b).x,layout.point(b).y],"kind":"walk"})
