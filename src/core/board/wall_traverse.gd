class_name WallTraverse
extends RefCounted
## Narrow masonry can be scaled even without a base-sized deck on top.
## A crest is a restricted climbing position, never a spawn or teleport floor.
## Both faces must offer a physically clear route before it is installed.
const SPACING := 1.0
const MAX_RISE := 12.0

static func add(layout: FloorLayout,data: Dictionary) -> void:
	var decks: Array[FloorSurface]=[]
	for s in layout.surfaces:
		if not s.id.begins_with("climb:") and not s.id.begins_with("bridge:") and is_equal_approx(s.level,s.end_level):
			decks.append(s)
	for entry: Array in data.get("solids",[]):
		if entry.size()!=6:
			continue
		var rect:=Rect2(float(entry[0]),float(entry[2]),float(entry[3]),float(entry[5]))
		_rectangle(layout,decks,rect,float(entry[1]),float(entry[4]),"solid:"+str(entry))
	for entry: Dictionary in data.get("convex_solids",[]):
		if not ConvexCrumble.straight_wall(entry):
			continue
		var profile: Array=entry["profile"]
		var a:=Vector2(profile[0][0],profile[0][2])
		var b:=Vector2(profile[1][0],profile[1][2])
		var d:=Vector2(profile[3][0],profile[3][2])
		var along:=b-a
		var across:=d-a
		if along.length()<across.length():
			var swap:=along
			along=across
			across=swap
		_strip(layout,decks,a+(along+across)*0.5,along,across,float(profile[0][1]),float(entry["extrusion"][1]),"prism:"+str(profile)+":"+str(entry["extrusion"]))
	for entry: Dictionary in data.get("walls",[]):
		# Explicitly permitted architectural walls only. Scenario obstacles
		# such as guardian columns and supernatural orbs stay excluded.
		if not bool(entry.get("climb_across",false)):
			continue
		var r: Array=entry["rect"]
		_rectangle(layout,decks,Rect2(r[0],r[1],r[2],r[3]),float(entry["height"]),float(entry.get("thickness",3.0)),str(entry["id"]))

static func _rectangle(layout: FloorLayout,decks: Array[FloorSurface],r: Rect2,base: float,rise: float,id: String) -> void:
	var along:=Vector2(r.size.x,0)
	var across:=Vector2(0,r.size.y)
	if across.length()>along.length():
		var swap:=along
		along=across
		across=swap
	_strip(layout,decks,r.get_center(),along,across,base,rise,id)

static func _strip(layout: FloorLayout,decks: Array[FloorSurface],center: Vector2,along: Vector2,across: Vector2,base: float,rise: float,id: String) -> void:
	if rise<1.0 or rise>MAX_RISE or along.length()<1.0 or across.length()>=Figure.BASE_RADIUS*2.0-0.001 or across.length()<0.001:
		return
	var normal:=across.normalized()
	var count:=maxi(1,ceili(along.length()/SPACING))
	var top:=base+rise
	for i in count:
		var mid:=center+along*((float(i)+0.5)/count-0.5)
		var crest:=MoveGrid.to_pos(MovePlanner.node_at(mid))
		var world:=Vector3(crest.x,top,crest.y)
		if not layout.clearance(world,Figure.BASE_RADIUS,1.6):
			continue
		# Do not duplicate an already standable roof or deck.
		var supported:=false
		for s in decks:
			if absf(s.level-top)<0.001 and layout.standable(layout.node(s.id,crest)):
				supported=true
				break
		if supported:
			continue
		var left:=_approach(layout,decks,mid-across*0.5,-normal,base,world)
		var right:=_approach(layout,decks,mid+across*0.5,normal,base,world)
		if left.is_empty() or right.is_empty():
			continue
		var key:="auto:cross:%s:%d:%d"%[id,roundi(crest.x*2),roundi(crest.y*2)]
		var sid:="climb:"+key+":crest"
		if layout.index_of(sid)>=0:
			continue
		var s:=FloorSurface.new()
		s.id=sid
		s.rect=Rect2(crest-Vector2.ONE*Figure.BASE_RADIUS,Vector2.ONE*Figure.BASE_RADIUS*2)
		s.level=top
		s.end_level=top
		layout.surfaces.append(s)
		for a: Vector3i in left:
			_connect(layout,a,sid,crest,key+":a:"+layout.surface_id(a))
		for a: Vector3i in right:
			_connect(layout,a,sid,crest,key+":b:"+layout.surface_id(a))

static func _approach(layout: FloorLayout,decks: Array[FloorSurface],face: Vector2,normal: Vector2,base: float,crest: Vector3) -> Array[Vector3i]:
	var out: Array[Vector3i]=[]
	# Clearance is a square footprint; its projected radius is larger
	# on angled faces. Round outward rather than through the masonry.
	var margin:=Figure.BASE_RADIUS*(absf(normal.x)+absf(normal.y))
	var desired:=face+normal*margin
	var snapped:=MoveGrid.to_pos(MovePlanner.node_at(desired))
	var best:=Vector2.INF
	var error:=INF
	for dx in range(-1,2):
		for dy in range(-1,2):
			var p:=snapped+Vector2(dx,dy)*MoveGrid.STEP
			var delta:=p-desired
			if delta.dot(normal)<-0.001 or p.distance_to(Vector2(crest.x,crest.z))>1.5:
				continue
			if delta.length_squared()<error:
				best=p
				error=delta.length_squared()
	if best==Vector2.INF:
		return out
	for s in decks:
		var a:=layout.node(s.id,best)
		if not layout.standable(a):
			continue
		var h:=layout.height(a)
		if h<base-0.01 or h>=crest.y-0.001 or crest.y-h>MAX_RISE:
			continue
		if _clear(layout,layout.world(a),crest):
			out.append(a)
	return out

static func _clear(layout: FloorLayout,start: Vector3,finish: Vector3) -> bool:
	var above:=Vector3(start.x,finish.y,start.z)
	for pair: Array in [[start,above],[above,finish]]:
		var a: Vector3=pair[0]
		var b: Vector3=pair[1]
		var steps:=maxi(1,ceili(a.distance_to(b)*10.0))
		for i in range(steps+1):
			if not layout.clearance(a.lerp(b,float(i)/steps),Figure.BASE_RADIUS,1.6):
				return false
	return true

static func _connect(layout: FloorLayout,a: Vector3i,sid: String,crest: Vector2,id: String) -> void:
	var p:=layout.point(a)
	FloorClimb.add(layout,{"id":id,"from":[layout.surface_id(a),p.x,p.y],"to":[sid,crest.x,crest.y]})
