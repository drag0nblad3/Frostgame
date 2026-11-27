class_name FloorLayout
extends RefCounted
## Opt-in layered geometry. Indices are ephemeral; authored IDs survive checkpoints.
var surfaces: Array[FloorSurface] = []
var solids: Array[AABB] = []
## These volumes are rendered by their corresponding TerrainPiece.
var magic_solids: Array[AABB]=[]
var links: Dictionary = {}
var errors: Array[String] = []


static func from_dict(d: Dictionary) -> FloorLayout:
	var layout := FloorLayout.new()
	for error in d.get("assembly_errors",[]):
		layout.errors.append(str(error))
	for entry: Dictionary in d.get("surfaces",[]):
		var s := FloorSurface.from_dict(entry)
		if s.id.is_empty() or layout.index_of(s.id)>=0 or s.rect.size.x<=0.0 or s.rect.size.y<=0.0:
			layout.errors.append("Invalid or duplicate surface: "+s.id)
			continue
		layout.surfaces.append(s)
	for entry: Array in d.get("solids",[]):
		if entry.size()!=6 or float(entry[3])<=0.0 or float(entry[4])<=0.0 or float(entry[5])<=0.0:
			layout.errors.append("Invalid solid volume")
			continue
		layout.solids.append(AABB(Vector3(entry[0],entry[1],entry[2]),Vector3(entry[3],entry[4],entry[5])))
	for entry: Dictionary in d.get("links",[]):
		layout._add_link(entry)
	for entry: Dictionary in d.get("climbs",[]):
		FloorClimb.add(layout,entry)
	for bridge: Dictionary in d.get("bridges",[]):
		var s := FloorSurface.from_dict(bridge["surface"])
		if layout.index_of(s.id)>=0:
			layout.errors.append("Duplicate dynamic surface: "+s.id)
			continue
		layout.surfaces.append(s)
		for entry: Dictionary in bridge["links"]:
			layout._add_link(entry)
	for wall: Dictionary in d.get("walls",[]):
		FloorWall.add_volume(layout,wall)
	for wall: Dictionary in d.get("walls",[]):
		FloorWall.add_climbs(layout,wall)
	return layout


func index_of(id: String) -> int:
	for i in surfaces.size():
		if surfaces[i].id == id:
			return i
	return -1


func node(id: String,p: Vector2) -> Vector3i:
	var n := MovePlanner.node_at(p)
	return Vector3i(n.x,n.y,index_of(id))


func point(n: Vector3i) -> Vector2:
	return MoveGrid.to_pos(Vector2i(n.x,n.y))


func height(n: Vector3i) -> float:
	return surfaces[n.z].height_at(point(n))


func world(n: Vector3i) -> Vector3:
	var p := point(n)
	return Vector3(p.x,height(n),p.y)


func surface_id(n: Vector3i) -> String:
	return surfaces[n.z].id


func contains(n: Vector3i,radius: float = Figure.BASE_RADIUS) -> bool:
	return n.z>=0 and n.z<surfaces.size() and surfaces[n.z].contains(point(n),radius)


func standable(n: Vector3i,radius: float = Figure.BASE_RADIUS, body: float = 1.6) -> bool:
	return contains(n,radius) and clearance(world(n),radius,body)


func clearance(at: Vector3,radius: float,body: float) -> bool:
	# Ignore a supporting slab that ends exactly at the soles.
	var box := AABB(at+Vector3(-radius,0.002,-radius),Vector3(radius*2.0,body,radius*2.0))
	for solid in solids:
		if solid.intersects(box):
			return false
	return true


func nodes_at(p: Vector2) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	for s in surfaces:
		var n := node(s.id,p)
		if standable(n):
			out.append(n)
	return out


func _add_link(d: Dictionary) -> void:
	var from: Array = d.get("from",[])
	var to: Array = d.get("to",[])
	if from.size()!=3 or to.size()!=3:
		errors.append("Malformed floor connection")
		return
	var a := node(str(from[0]),Vector2(from[1],from[2]))
	var b := node(str(to[0]),Vector2(to[1],to[2]))
	if not standable(a) or not standable(b) or a==b:
		errors.append("Invalid connection endpoints: "+str(from)+" -> "+str(to))
		return
	if not point(a).is_equal_approx(Vector2(from[1],from[2])) or not point(b).is_equal_approx(Vector2(to[1],to[2])):
		errors.append("Connection endpoints must align to half-inch lattice")
		return
	var kind := str(d.get("kind","stairs"))
	if not kind in ["stairs","ladder","climb","walk"]:
		errors.append("Unsupported connection kind: "+kind)
		return
	var distance := world(a).distance_to(world(b))
	var steps := maxi(1,ceili(distance/0.1))
	for i in range(1,steps):
		if not clearance(world(a).lerp(world(b),float(i)/steps),Figure.BASE_RADIUS,1.6):
			errors.append("Connection crosses a solid: "+str(from)+" -> "+str(to))
			return
	if kind=="climb":
		distance = point(a).distance_to(point(b))+ceilf(absf(height(a)-height(b)))*2.0
	var edge := {"to":b,"cost":distance,"kind":kind}
	if not links.has(a):
		links[a]=[]
	links[a].append(edge)
	if not bool(d.get("one_way",false)):
		if not links.has(b):
			links[b]=[]
		links[b].append({"to":a,"cost":distance,"kind":kind})
