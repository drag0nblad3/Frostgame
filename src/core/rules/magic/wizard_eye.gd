class_name WizardEye
extends RefCounted

## The controller owns this helper; avoid a RefCounted ownership cycle.
var _controller_ref: WeakRef
var c: GameController:
	get:
		return _controller_ref.get_ref() as GameController


func _init(controller: GameController) -> void:
	_controller_ref=weakref(controller)


func options(f: Figure) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var b := c.state.board
	if not b.floor_layout.is_empty():
		return floor_options(f)
	for p in b.pieces:
		if p.kind.id.begins_with("null_") or p.kind.id == "temple_column" or p.circular or p.ramp or p.kind.height < 0.5 or p.kind.id.begins_with("spell_") and p.kind.id != "spell_wall":
			continue
		var center := p.rect.get_center()
		for direction: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			var at := center + direction * (absf(direction.x) * p.rect.size.x * 0.5 + absf(direction.y) * p.rect.size.y * 0.5 + 0.15)
			if b.contains(at) and f.pos.distance_to(at) <= 12.0 and LineOfSight.check(b, f.pos, at,f).clear:
				result.append({"kind": "eye_face", "target": f.id, "piece": p, "at": at, "direction": direction, "label": "%s at %.1f, %.1f — %s face" % [p.kind.name, at.x, at.y, ["east", "south", "west", "north"][posmod(roundi(direction.angle() / (PI * 0.5)), 4)]]})
	return result


func floor_options(f: Figure) -> Array[Dictionary]:
	var out: Array[Dictionary]=[]
	var b:=c.state.board
	var layout:=b.floor_geometry()
	var eye:=Vector3(f.pos.x,f.elevation+1.5,f.pos.y)
	for solid in layout.solids:
		if solid.size.y<0.5:
			continue
		var rect:=Rect2(solid.position.x,solid.position.z,solid.size.x,solid.size.z)
		var host: TerrainPiece=null
		var row: Array=[]
		for p in b.pieces:
			if not p.dynamic_surface.is_empty() and p.rect==rect and is_equal_approx(p.base_height,solid.position.y):
				host=p
				break
		if host==null:
			for entry: Array in b.floor_layout.get("solids",[]):
				if AABB(Vector3(entry[0],entry[1],entry[2]),Vector3(entry[3],entry[4],entry[5]))==solid:
					row=entry.duplicate()
					break
			if row.is_empty():
				continue
		for direction: Vector2 in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
			var at:=rect.get_center()+direction*(absf(direction.x)*rect.size.x*0.5+absf(direction.y)*rect.size.y*0.5+0.15)
			var height:=solid.position.y+minf(1.5,solid.size.y*0.5)
			var world:=Vector3(at.x,height,at.y)
			if not b.contains(at) or ScenarioNull.field_at(b,at,0.0) or eye.distance_to(world)>12.0 or not LineOfSight.floor_ray(b,layout,eye,world,f):
				continue
			out.append({"kind":"eye_face","target":f.id,"piece":host,"eye_solid":row,"at":at,"height":height,"direction":direction,"label":"Wall face at %.1f, %.1f · elevation %.1f"%[at.x,at.y,height]})
	return out


static func host_valid(b: Board,p: TerrainPiece) -> bool:
	return b.pieces.has(p.eye_host) if p.eye_solid.is_empty() else b.floor_layout.get("solids",[]).has(p.eye_solid)


## The actual remote ray origin. Direct physical sight remains separate
## for shooting, thrown objects, teleportation and contact.
static func floor_origin(b: Board,f: Figure,at: Vector3,limit: float=24.0,target_offset: float=1.0) -> Variant:
	var layout:=b.floor_geometry()
	var feet:=Vector3(f.pos.x,f.elevation,f.pos.y)
	var target:=at+Vector3.UP*target_offset
	if RealityCrackGeometry.world_distance(b,feet,at)<=limit+0.001 and LineOfSight.floor_ray(b,layout,feet+Vector3.UP*1.5,target,f):
		return feet+Vector3.UP*1.5
	var p:=marker(b,f)
	if p==null or ScenarioNull.muted(f):
		return null
	var point:=p.rect.get_center()
	var remote:=Vector3(point.x,p.base_height,point.y)
	if p.eye_direction.dot(Vector2(at.x,at.z)-point)>=-0.001 and RealityCrackGeometry.world_distance(b,remote,target)<=limit+0.001 and LineOfSight.floor_ray(b,layout,remote,target,f):
		return remote
	return null


static func marker(b: Board, f: Figure) -> TerrainPiece:
	for p in b.pieces:
		if p.kind.id == "spell_wizard_eye" and p.caster_id == f.id and host_valid(b,p):
			return p
	return null


static func origin(b: Board, f: Figure, at: Vector2, max_range: float = 24.0) -> Vector2:
	if Vector2(RealityCrackGeometry.sight_distance(b,f.pos,at), f.elevation - b.height_at(at)).length() <= max_range and LineOfSight.check(b, f.pos, at,f).clear:
		return f.pos
	var eye := marker(b, f)
	if eye != null:
		var pos := eye.rect.get_center()
		if eye.eye_direction.dot(at - pos) >= -0.001 and Vector2(pos.distance_to(at), b.height_at(pos) - b.height_at(at)).length() <= max_range and LineOfSight.check(b, pos, at,f).clear:
			return pos
	return f.pos


static func visible(b: Board, f: Figure, at: Vector2, max_range: float = 24.0) -> bool:
	var start := origin(b, f, at, max_range)
	return Vector2(RealityCrackGeometry.sight_distance(b,start,at), b.height_at(start) - b.height_at(at)).length() <= max_range and LineOfSight.check(b, start, at,f).clear


func create(f: Figure, option: Dictionary) -> void:
	var b := c.state.board
	var previous := marker(b, f)
	if previous != null:
		b.pieces.erase(previous)
	var host: TerrainPiece = option["piece"]
	var row: Array=option.get("eye_solid",[])
	if not b.pieces.has(host) and (row.is_empty() or not b.floor_layout.get("solids",[]).has(row)):
		return
	var k := TerrainKind.new()
	k.id = "spell_wizard_eye"
	k.name = "Wizard Eye"
	k.height = 0.25
	var at: Vector2 = option["at"]
	var p := TerrainPiece.new(k, Rect2(at - Vector2(0.15, 0.15), Vector2(0.3, 0.3)))
	p.circular = true
	p.cast_turn = c.state.turn
	p.caster_id = f.id
	p.eye_host = host
	p.eye_solid=row.duplicate()
	if not b.floor_layout.is_empty():
		p.base_height=float(option["height"])
		p.surface_id="eye_face"
	p.eye_direction = option["direction"]
	b.pieces.append(p)
	b.invalidate_terrain()
	c.emit("terrain_changed", {"spell": "wizard_eye", "created": true})


static func remove_attached(b: Board, host: TerrainPiece) -> void:
	for p in b.pieces.duplicate():
		if p.kind.id == "spell_wizard_eye" and p.eye_host == host:
			b.pieces.erase(p)
