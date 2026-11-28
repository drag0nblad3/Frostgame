class_name FloorLayout
extends RefCounted
## Opt-in layered geometry. Indices are ephemeral; authored IDs survive checkpoints.
var surfaces: Array[FloorSurface] = []
var solids: Array[AABB] = []
var convex_solids: Array[ArchitecturePrism] = []
## Upright circular obstacles use a true radial footprint, not a square proxy.
var circular_solids: Array[AABB]=[]
## These volumes are rendered by their corresponding TerrainPiece.
var magic_solids: Array[AABB]=[]
var links: Dictionary = {}
var errors: Array[String] = []
## Derived IDs are queried in large numbers by the movement graph. Cache
## successful lookups; append-only layout assembly preserves their indices.
var _surface_indices: Dictionary={}
var _indexed_count:=0
var profiled_ground: FloorSurface
## Terrain-only answers survive separate reach searches on the same immutable
## geometry. Never memoize during assembly, when solids can still be appended.
var _sealed:=false
var _standing: Dictionary={}
var _midpoints: Dictionary={}


static func from_dict(d: Dictionary) -> FloorLayout:
	var layout := FloorLayout.new()
	for error in d.get("assembly_errors",[]):
		layout.errors.append(str(error))
	for entry: Dictionary in d.get("surfaces",[]):
		var s := FloorSurface.from_dict(entry)
		if s.id.is_empty() or layout.index_of(s.id)>=0 or s.rect.size.x<=0.0 or s.rect.size.y<=0.0 or not s.polygon_valid:
			layout.errors.append("Invalid or duplicate surface: "+s.id)
			continue
		if not s.polygon.is_empty():
			var slab:=s.deck_volume()
			if not slab.valid:
				layout.errors.append("Invalid polygon deck: "+s.id)
				continue
			layout.convex_solids.append(slab)
		layout.surfaces.append(s)
		if not s.profiles.is_empty():
			layout.profiled_ground=s
	for entry: Array in d.get("solids",[]):
		if entry.size()!=6 or float(entry[3])<=0.0 or float(entry[4])<=0.0 or float(entry[5])<=0.0:
			layout.errors.append("Invalid solid volume")
			continue
		layout.solids.append(AABB(Vector3(entry[0],entry[1],entry[2]),Vector3(entry[3],entry[4],entry[5])))
	for entry: Dictionary in d.get("convex_solids",[]):
		var prism:=ArchitecturePrism.from_dict(entry)
		if not prism.valid:
			layout.errors.append("Invalid convex architecture profile")
			continue
		layout.convex_solids.append(prism)
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
	if d.get("auto_architecture_climbs",false):
		ArchitectureClimbs.add(layout)
		WallTraverse.add(layout,d)
	layout._sealed=true
	return layout


func index_of(id: String) -> int:
	if _indexed_count>surfaces.size():
		_surface_indices.clear()
		_indexed_count=0
	while _indexed_count<surfaces.size():
		_surface_indices[surfaces[_indexed_count].id]=_indexed_count
		_indexed_count+=1
	var index:=int(_surface_indices.get(id,-1))
	if index>=0 and index<surfaces.size() and surfaces[index].id==id:
		return index
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
	if not _sealed or not is_equal_approx(radius,Figure.BASE_RADIUS) or not is_equal_approx(body,1.6):
		return contains(n,radius) and clearance(world(n),radius,body)
	if not _standing.has(n):
		_standing[n]=contains(n,radius) and clearance(world(n),radius,body)
	return _standing[n]


## Geometry-only horizontal neighbor check shared by all movers and searches.
## Restriction checks (figures, wards, scenario boundaries) remain per mover.
func neighbor_clear(a: Vector3i,b: Vector3i) -> bool:
	var key:=Vector3i(a.x+b.x,a.y+b.y,a.z)
	if _sealed and _midpoints.has(key):
		return _midpoints[key]
	var midpoint:=world(a).lerp(world(b),0.5)
	if not surfaces[a.z].profiles.is_empty():
		midpoint.y=surfaces[a.z].height_at(Vector2(midpoint.x,midpoint.z))
	var p:=Vector2(midpoint.x,midpoint.z)
	if not _sealed:
		return surfaces[a.z].contains(p,Figure.BASE_RADIUS) and clearance(midpoint,Figure.BASE_RADIUS,1.6)
	if not _midpoints.has(key):
		_midpoints[key]=surfaces[a.z].contains(p,Figure.BASE_RADIUS) and clearance(midpoint,Figure.BASE_RADIUS,1.6)
	return _midpoints[key]


func clearance(at: Vector3,radius: float,body: float) -> bool:
	if profiled_ground!=null and at.y<profiled_ground.height_at(Vector2(at.x,at.z))-0.002:
		return false
	# During assembly volumes are mutable; use the original full scan.
	# Large bases also retain the full scan. Normal figures and spell
	# trajectories query a conservative neighborhood of static geometry.
	if not _sealed or radius>1.0 or solids.size()+circular_solids.size()+convex_solids.size()<16:
		return _clearance_volumes(at,radius,body,solids,circular_solids,convex_solids)
	_prepare_clearance_index()
	var key:=_clearance_cell(Vector2(at.x,at.z))
	if not _clearance_cells.has(key):
		return true
	var bucket: Array=_clearance_cells[key]
	return _clearance_volumes(at,radius,body,bucket[0],bucket[1],bucket[2])


func _clearance_volumes(at: Vector3,radius: float,body: float,boxes: Array,cylinders: Array,prisms: Array) -> bool:
	# Ignore a supporting slab that ends exactly at the soles.
	var box := AABB(at+Vector3(-radius,0.002,-radius),Vector3(radius*2.0,body,radius*2.0))
	for solid: AABB in boxes:
		if solid.intersects(box):
			return false
	for cylinder: AABB in cylinders:
		var center:=Vector2(cylinder.get_center().x,cylinder.get_center().z)
		if at.y+0.002<cylinder.end.y and at.y+body>cylinder.position.y and Vector2(at.x,at.z).distance_to(center)<cylinder.size.x*0.5+radius-0.001:
			return false
	for prism: ArchitecturePrism in prisms:
		if prism.overlaps(box):
			return false
	return true


## Four-inch horizontal broad phase. Expand footprints by the maximum
## indexed base radius; any volume that might touch a base is in its bin.
## Actual height, radial and convex overlap tests remain unchanged.
const CLEARANCE_CELL_SIZE:=4.0
var _clearance_cells: Dictionary={}
var _clearance_counts:=Vector3i(-1,-1,-1)

func _clearance_cell(p: Vector2) -> Vector2i:
	return Vector2i(floori(p.x/CLEARANCE_CELL_SIZE),floori(p.y/CLEARANCE_CELL_SIZE))


func _index_clearance_volume(rect: Rect2,kind: int,volume: Variant) -> void:
	var grown:=rect.grow(1.001)
	var lo:=_clearance_cell(grown.position)
	var hi:=_clearance_cell(grown.end)
	for x in range(lo.x,hi.x+1):
		for y in range(lo.y,hi.y+1):
			var key:=Vector2i(x,y)
			if not _clearance_cells.has(key):
				_clearance_cells[key]=[[],[],[]]
			_clearance_cells[key][kind].append(volume)


func _prepare_clearance_index() -> void:
	var counts:=Vector3i(solids.size(),circular_solids.size(),convex_solids.size())
	if counts==_clearance_counts:
		return
	_clearance_cells.clear()
	for solid in solids:
		_index_clearance_volume(Rect2(Vector2(solid.position.x,solid.position.z),Vector2(solid.size.x,solid.size.z)),0,solid)
	for cylinder in circular_solids:
		# Preserve the exact cylinder test's x-radius even if its stored
		# z extent differs. The broad phase must never miss such a volume.
		var center:=cylinder.get_center()
		var diameter:=cylinder.size.x
		_index_clearance_volume(Rect2(Vector2(center.x,center.z)-Vector2.ONE*diameter*0.5,Vector2.ONE*diameter),1,cylinder)
	for prism in convex_solids:
		var bounds:=prism.bounds
		_index_clearance_volume(Rect2(Vector2(bounds.position.x,bounds.position.z),Vector2(bounds.size.x,bounds.size.z)),2,prism)
	_clearance_counts=counts


func nodes_at(p: Vector2) -> Array[Vector3i]:
	var out: Array[Vector3i] = []
	var xy:=MovePlanner.node_at(p)
	for i in surfaces.size():
		var n:=Vector3i(xy.x,xy.y,i)
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


## Coarse static portal graph for AI guidance. Group nearby links between
## the same supports; exact half-inch movement still validates every edge.
## The owning Board replaces this layout when geometry changes.
var _coarse_ready:=false
var _coarse_out: Dictionary={}
var _coarse_in: Dictionary={}
var _coarse_hops: Dictionary={}

func prepare_coarse_navigation() -> void:
	if _coarse_ready:
		return
	_coarse_ready=true
	var sectors: Dictionary={}
	for from: Vector3i in links:
		for edge: Dictionary in links[from]:
			var to: Vector3i=edge["to"]
			if from.z==to.z:
				continue
			var key:=Vector4i(floori(float(from.x)/8.0),floori(float(from.y)/8.0),from.z,to.z)
			if sectors.has(key):
				continue
			sectors[key]=true
			if not _coarse_out.has(from.z):
				_coarse_out[from.z]=[]
			_coarse_out[from.z].append({"from":from,"to":to})
			if not _coarse_in.has(to.z):
				_coarse_in[to.z]=[]
			if not _coarse_in[to.z].has(from.z):
				_coarse_in[to.z].append(from.z)

func coarse_hops(goal_floor: int) -> Dictionary:
	prepare_coarse_navigation()
	if _coarse_hops.has(goal_floor):
		return _coarse_hops[goal_floor]
	var distances: Dictionary={goal_floor:0}
	var queue: Array[int]=[goal_floor]
	var cursor:=0
	while cursor<queue.size():
		var current:=queue[cursor]
		cursor+=1
		for previous: int in _coarse_in.get(current,[]):
			if not distances.has(previous):
				distances[previous]=int(distances[current])+1
				queue.append(previous)
	_coarse_hops[goal_floor]=distances
	return distances

## Approximate remaining distance via a coarse portal. It is intentionally
## not a rules validator or an admissible exact-search heuristic.
func coarse_distance(from: Vector3i,to: Vector3i) -> float:
	var direct:=point(from).distance_to(point(to))
	if from.z<0 or to.z<0:
		return direct
	if from.z==to.z:
		return coarse_horizontal_distance(from,to)
	var hops:=coarse_hops(to.z)
	if not hops.has(from.z):
		return direct+8.0
	var best:=INF
	for portal: Dictionary in _coarse_out.get(from.z,[]):
		var a: Vector3i=portal["from"]
		var b: Vector3i=portal["to"]
		if not hops.has(b.z) or int(hops[b.z])>=int(hops[from.z]):
			continue
		var after:=point(b).distance_to(point(to)) if b.z==to.z else float(hops[b.z])*4.0
		best=minf(best,point(from).distance_to(point(a))+1.0+after)
	return best if is_finite(best) else direct+8.0


## Static two-inch waypoint lattice, derived lazily per geometry revision.
## A coarse edge must be supported and clear along the full fine lattice.
## Dynamic figures, wards and scenario rules are still checked by LayeredGrid.
const COARSE_STRIDE:=4
const COARSE_FIELD_LIMIT:=500
const COARSE_FIELD_COUNT:=12
var _horizontal_edges: Dictionary={}
var _horizontal_fields: Dictionary={}
var _horizontal_order: Array[Vector3i]=[]

func _coarse_anchor(n: Vector3i) -> Vector3i:
	return Vector3i(roundi(float(n.x)/COARSE_STRIDE)*COARSE_STRIDE,roundi(float(n.y)/COARSE_STRIDE)*COARSE_STRIDE,n.z)


func _coarse_neighbors(n: Vector3i) -> Array[Vector3i]:
	if _horizontal_edges.has(n):
		var cached: Array[Vector3i]=_horizontal_edges[n]
		return cached
	var out: Array[Vector3i]=[]
	if standable(n):
		for direction: Vector2i in MoveGrid.NEIGHBORS:
			var delta:=Vector3i(direction.x,direction.y,0)
			var previous:=n
			var clear:=true
			for i in range(1,COARSE_STRIDE+1):
				var next:=n+delta*i
				if not standable(next) or not neighbor_clear(previous,next):
					clear=false
					break
				previous=next
			if clear:
				out.append(previous)
	_horizontal_edges[n]=out
	return out


## Reverse distance field: all figures targeting the same coarse cell reuse
## one geometry-only calculation. Bounded cache prevents moving enemies
## from accumulating an unbounded number of fields.
func _horizontal_field(goal: Vector3i) -> Dictionary:
	if _horizontal_fields.has(goal):
		return _horizontal_fields[goal]
	if not standable(goal):
		return {}
	var distances: Dictionary={goal:0.0}
	var heap:=MinHeap.new()
	heap.push(0.0,goal)
	var expanded:=0
	while not heap.is_empty() and expanded<COARSE_FIELD_LIMIT:
		var item:=heap.pop()
		var n: Vector3i=item[1]
		var distance: float=item[0]
		if distance>float(distances[n])+0.0001:
			continue
		expanded+=1
		for next in _coarse_neighbors(n):
			var cost:=distance+point(n).distance_to(point(next))
			if cost<float(distances.get(next,INF)):
				distances[next]=cost
				heap.push(cost,next)
	if _horizontal_order.size()>=COARSE_FIELD_COUNT:
		_horizontal_fields.erase(_horizontal_order.pop_front())
	_horizontal_order.append(goal)
	_horizontal_fields[goal]=distances
	return distances


func coarse_horizontal_distance(from: Vector3i,to: Vector3i) -> float:
	var direct:=point(from).distance_to(point(to))
	# Local decisions, empty terrain and narrow/climb supports retain the
	# cheap direct estimate. Coarse failure is never proof of no route.
	if direct<4.0 or from.z!=to.z or from.z<0 or from.z>=surfaces.size():
		return direct
	if solids.is_empty() and convex_solids.is_empty() and circular_solids.is_empty() and magic_solids.is_empty() and surfaces[from.z].profiles.is_empty():
		return direct
	if surfaces[from.z].id.begins_with("climb:"):
		return direct
	var a:=_coarse_anchor(from)
	var b:=_coarse_anchor(to)
	if not standable(a) or not standable(b):
		return direct
	var distances:=_horizontal_field(b)
	if not distances.has(a):
		return direct
	# Reduce quantization error at either endpoint, preserving direct
	# distance as the fallback. This estimate is for imperfect AI only.
	var offset:=point(from).distance_to(point(a))+point(to).distance_to(point(b))
	return maxf(direct,float(distances[a])-offset)


## Ray broad phase shares the same conservative bins as figure clearance.
## Short/medium rays are common in combat and contact tests. For a very
## wide bounding rectangle, scanning the original arrays is cheaper.
func ray_volumes(a: Vector3,b: Vector3) -> Array:
	var all: Array=[solids,circular_solids,convex_solids]
	if not _sealed or solids.size()+circular_solids.size()+convex_solids.size()<16:
		return all
	var lo:=_clearance_cell(Vector2(minf(a.x,b.x),minf(a.z,b.z)))
	var hi:=_clearance_cell(Vector2(maxf(a.x,b.x),maxf(a.z,b.z)))
	if (hi.x-lo.x+1)*(hi.y-lo.y+1)>24:
		return all
	_prepare_clearance_index()
	if lo==hi:
		return _clearance_cells.get(lo,[[],[],[]])
	var out: Array=[[],[],[]]
	var seen: Array=[{},{},{}]
	for x in range(lo.x,hi.x+1):
		for y in range(lo.y,hi.y+1):
			var key:=Vector2i(x,y)
			if not _clearance_cells.has(key):
				continue
			var bucket: Array=_clearance_cells[key]
			for kind in 3:
				for volume in bucket[kind]:
					if not seen[kind].has(volume):
						seen[kind][volume]=true
						out[kind].append(volume)
	return out
