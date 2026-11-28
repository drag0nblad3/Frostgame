class_name FloorSurface
extends RefCounted
## A named, independently walkable surface. Inclines use an optional end height.
var id := ""
var rect := Rect2()
var level := 0.0
var end_level := 0.0
var axis_y := false
var rough := 1.0
## Optional ordered convex outline for a flat deck; rect is only its search bound.
var polygon:=PackedVector2Array()
var polygon_valid:=true
var deck_thickness:=0.0
## Serialized ground profiles are one continuous support, not stacked decks.
var profiles: Array[TerrainPiece]=[]


static func from_dict(d: Dictionary) -> FloorSurface:
	var s := FloorSurface.new()
	s.id = str(d["id"])
	var r: Array = d["rect"]
	s.rect = Rect2(float(r[0]),float(r[1]),float(r[2]),float(r[3]))
	s.level = float(d.get("level",0.0))
	s.end_level = float(d.get("end_level",s.level))
	s.axis_y = d.get("axis","x") == "y"
	s.rough = maxf(1.0,float(d.get("move_mult",1.0)))
	for entry: Dictionary in d.get("ground_profiles",[]):
		var r0: Array=entry["rect"]
		var k:=TerrainKind.new()
		k.ground_surface=true
		k.stairs=bool(entry.get("stairs",false))
		var p:=TerrainPiece.new(k,Rect2(r0[0],r0[1],r0[2],r0[3]))
		p.level=float(entry.get("level",0.0))
		var ramp: Dictionary=entry.get("ramp",{})
		if not ramp.is_empty():
			p.ramp=true
			p.ramp_rotated=ramp.get("axis","x")=="y"
			p.ramp_start=float(ramp.get("start",0.0))
			p.ramp_end=float(ramp.get("end",0.0))
		s.profiles.append(p)
	if d.has("polygon"):
		for vertex in d["polygon"]:
			if not vertex is Array or vertex.size()!=2:
				s.polygon_valid=false
				return s
			s.polygon.append(Vector2(vertex[0],vertex[1]))
		s.polygon_valid=s._validate_polygon() and is_equal_approx(s.level,s.end_level)
		s.deck_thickness=float(d.get("deck_thickness",0.35))
		if s.deck_thickness<=0.0:
			s.polygon_valid=false
	return s


func profile_at(p: Vector2) -> TerrainPiece:
	for i in range(profiles.size()-1,-1,-1):
		if profiles[i].contains(p):
			return profiles[i]
	return null


func height_at(p: Vector2) -> float:
	if not profiles.is_empty():
		var profile:=profile_at(p)
		return profile.surface_height(p) if profile!=null else level
	var run := rect.size.y if axis_y else rect.size.x
	var offset := p.y-rect.position.y if axis_y else p.x-rect.position.x
	return lerpf(level,end_level,clampf(offset/maxf(run,0.001),0.0,1.0))


func contains(p: Vector2, radius: float = 0.0) -> bool:
	if not polygon_valid:
		return false
	if not polygon.is_empty():
		# Convex half-spaces: enforce the circular base setback at every edge.
		for i in polygon.size():
			var a:=polygon[i]
			var edge:=polygon[(i+1)%polygon.size()]-a
			if edge.cross(p-a)/edge.length()<radius-0.001:
				return false
		return true
	return p.x >= rect.position.x+radius-0.001 and p.y >= rect.position.y+radius-0.001 and p.x <= rect.end.x-radius+0.001 and p.y <= rect.end.y-radius+0.001


func _validate_polygon() -> bool:
	if polygon.size()<3 or polygon.size()>32:
		return false
	var area:=0.0
	for i in polygon.size():
		area+=polygon[i].cross(polygon[(i+1)%polygon.size()])
	if absf(area)<0.001:
		return false
	if area<0.0:
		polygon.reverse()
	rect=Rect2(polygon[0],Vector2.ZERO)
	for vertex in polygon:
		rect=rect.expand(vertex)
	for i in polygon.size():
		var a:=polygon[i]
		var edge:=polygon[(i+1)%polygon.size()]-a
		if edge.length()<0.001:
			return false
		for vertex in polygon:
			if edge.cross(vertex-a)<-0.0001:
				return false
	return true


func deck_volume() -> ArchitecturePrism:
	var profile: Array=[]
	for at in polygon:
		profile.append([at.x,level-deck_thickness,at.y])
	return ArchitecturePrism.from_dict({"profile":profile,"extrusion":[0,deck_thickness,0]})
