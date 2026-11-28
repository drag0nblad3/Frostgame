class_name ConvexCrumble
extends RefCounted
## Straight wall prisms may be breached; designated structural piers can collapse their dependent floors.
## A lightweight TerrainPiece provides the existing spell target identity.
const KIND:="architecture_prism_target"


static func target(entry: Dictionary) -> TerrainPiece:
	var id:=str(entry.get("crumble_id",""))
	if id.is_empty():
		return null
	var prism:=ArchitecturePrism.from_dict(entry)
	if not prism.valid or not straight_wall(entry):
		return null
	var k:=TerrainKind.new()
	k.id=KIND
	k.name="Load-bearing support (collapses floor)" if entry.get("load_bearing",false) else "Angled masonry"
	k.height=prism.bounds.size.y
	var p:=TerrainPiece.new(k,Rect2(prism.bounds.position.x,prism.bounds.position.z,prism.bounds.size.x,prism.bounds.size.z))
	p.surface_id="street"
	p.base_height=prism.bounds.position.y
	p.dynamic_surface=id
	return p


static func straight_wall(entry: Dictionary) -> bool:
	var raw: Array=entry.get("profile",[])
	var e: Array=entry.get("extrusion",[])
	if raw.size()!=4 or e.size()!=3:
		return false
	var a:=v(raw[0])
	var b:=v(raw[1])
	var c:=v(raw[2])
	var d:=v(raw[3])
	return absf(float(e[0]))<0.001 and absf(float(e[2]))<0.001 and float(e[1])>0.0 and absf(a.y-b.y)<0.001 and absf(a.y-c.y)<0.001 and absf(a.y-d.y)<0.001 and (b-a).is_equal_approx(c-d) and absf((b-a).normalized().dot((d-a).normalized()))<0.001


static func v(raw: Array) -> Vector3:
	return Vector3(raw[0],raw[1],raw[2])


static func row(p: Vector3) -> Array:
	return [p.x,p.y,p.z]


static func entry_for(board: Board,id: String) -> Dictionary:
	for entry: Dictionary in board.floor_layout.get("convex_solids",[]):
		if str(entry.get("crumble_id",""))==id:
			return entry
	return {}


static func visible(board: Board,f: Figure,p: TerrainPiece) -> bool:
	var entry:=entry_for(board,p.dynamic_surface)
	if entry.is_empty():
		return false
	var prism:=ArchitecturePrism.from_dict(entry)
	if not prism.valid:
		return false
	var origin:=Vector3(f.pos.x,f.elevation+1.5,f.pos.y)
	var layout:=board.floor_geometry()
	for i in prism.faces.size():
		var face:=prism.faces[i]
		var normal:=prism.planes[i].normal
		if absf(normal.y)>0.5:
			continue
		var center:=Vector3.ZERO
		for index in face:
			center+=prism.vertices[index]
		center/=float(face.size())
		var at:=center+normal*0.05
		if normal.dot(origin-at)>0.0 and origin.distance_to(at)<=24.0 and LineOfSight.floor_ray(board,layout,origin,at,f):
			return true
	return false


static func breach(entry: Dictionary) -> Array:
	if not straight_wall(entry):
		return []
	var raw: Array=entry["profile"]
	var a:=v(raw[0])
	var b:=v(raw[1])
	var c:=v(raw[2])
	var d:=v(raw[3])
	var length:=a.distance_to(b)
	var fraction:=maxf(0.0,(length-1.5)*0.5/maxf(length,0.001))
	var result: Array=[]
	if fraction<0.001:
		return result
	for i in 2:
		var start:=0.0 if i==0 else 1.0-fraction
		var end:=fraction if i==0 else 1.0
		result.append({"profile":[row(a.lerp(b,start)),row(a.lerp(b,end)),row(d.lerp(c,end)),row(d.lerp(c,start))],"extrusion":entry["extrusion"].duplicate(),"crumble_id":str(entry["crumble_id"])+":part:"+str(i)})
	return result


static func apply(c: GameController,p: TerrainPiece) -> void:
	var board:=c.state.board
	var entry:=entry_for(board,p.dynamic_surface)
	if entry.is_empty() or not straight_wall(entry):
		return
	if bool(entry.get("load_bearing",false)):
		ArchitectureCollapse.apply(c,p)
		return
	var entries: Array=board.floor_layout.get("convex_solids",[])
	var parts:=breach(entry)
	entries.erase(entry)
	WizardEye.remove_attached(board,p)
	board.pieces.erase(p)
	for part: Dictionary in parts:
		entries.append(part)
		var handle:=target(part)
		if handle!=null:
			board.pieces.append(handle)
	board.floor_layout["convex_solids"]=entries
	board.invalidate_terrain()
	c.emit("terrain_changed",{"spell":"crumble","created":false})
