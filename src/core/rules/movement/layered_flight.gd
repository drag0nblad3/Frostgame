class_name LayeredFlight
extends RefCounted
## Core p.195: flyers ignore terrain penalties; still require clear air
## and a legal landing. Dimensional voids and boundaries remain impassable.
static func add(s: GameState,f: Figure,grid: LayeredGrid,r: LayeredReach,allowance: float) -> void:
	if not f.def.traits.has("flying") or not grid.layout.standable(r.start):
		return
	var l:=grid.layout
	var a:=l.world(r.start)
	for n in BattlePlacement.nodes(s.board,f.pos,allowance):
		if n==r.start or not grid.open(n):
			continue
		var b:=l.world(n)
		var cost:=a.distance_to(b)
		if cost>allowance+0.001 or cost>=float(r.cost.get(n,INF))-0.001 or BattleBoundary.blocks_end(s.board.boundaries,l.point(n)):
			continue
		if RedKingBridge.crosses_void(s.board,f.pos,l.point(n)) or not grid.segment_allowed(a,b) or RedKingVeil.lethal(s,f.pos,l.point(n)):
			continue
		var route:=air_route(s,f,l,a,b)
		if route.is_empty():
			continue
		if not r.prev.has(n):
			r.prev[n]=r.start
		r.cost[n]=cost
		r.air_paths[n]=route

static func air_route(s: GameState,f: Figure,l: FloorLayout,a: Vector3,b: Vector3) -> PackedVector3Array:
	# Ascend and descend in clear space, never through a ceiling. Charge
	# endpoint distance; the clearance altitude has no climb surcharge.
	var low:=maxf(a.y,b.y)+2.0
	for i in range(21):
		var h:=low+float(i)*0.5
		var up:=Vector3(a.x,h,a.z)
		var down:=Vector3(b.x,h,b.z)
		if not _clear(s,f,l,a,up) or not _clear(s,f,l,down,b):
			break
		if _clear(s,f,l,up,down):
			return PackedVector3Array([a,up,down,b])
	return PackedVector3Array()

static func _clear(s: GameState,f: Figure,l: FloorLayout,a: Vector3,b: Vector3) -> bool:
	var steps:=maxi(1,ceili(a.distance_to(b)*4.0))
	for i in range(steps+1):
		var at:=a.lerp(b,float(i)/steps)
		var p:=Vector2(at.x,at.z)
		if not l.clearance(at,Figure.BASE_RADIUS,1.6) or ScenarioNull.field_at(s.board,p) or TerrainMagic.ward_blocks(s.board,f,p,at.y):
			return false
		for other in s.figures:
			if other!=f and other.in_play() and other.ring_side==f.ring_side and absf(other.elevation-at.y)<0.5 and other.pos.distance_to(p)<Contact.OVERLAP:
				return false
	return true
