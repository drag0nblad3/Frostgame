class_name ArchitectureCollapse
extends RefCounted
## Authored dependency graph. No inferred structural physics: only marked
## critical piers and their named dependants can collapse. All mutations precede
## the standard support-removal/fall pipeline, including chained spell supports.


static func affected(source: Dictionary,support: String) -> Dictionary:
	var supports: Array[String]=[support]
	var floors: Array[String]=[]
	var climbs: Array[String]=[]
	var changed:=true
	while changed:
		changed=false
		for volume: Dictionary in source.get("convex_solids",[]):
			if supports.has(str(volume.get("requires_support",""))):
				var id:=str(volume.get("crumble_id",""))
				if not id.is_empty() and not supports.has(id):
					supports.append(id)
					changed=true
		for surface: Dictionary in source.get("surfaces",[]):
			var id:=str(surface["id"])
			if supports.has(str(surface.get("requires_support",""))) and not floors.has(id):
				floors.append(id)
				changed=true
		for bridge: Dictionary in source.get("bridges",[]):
			var id:=str(bridge["surface"]["id"])
			if floors.has(id):
				continue
			for edge: Dictionary in bridge.get("links",[]):
				if endpoint_lost(edge,floors,climbs):
					floors.append(id)
					changed=true
					break
		for wall: Dictionary in source.get("walls",[]):
			var id:=str(wall["id"])
			if floor_lost(str(wall["support"]),floors,climbs) and not floors.has(id):
				floors.append(id)
				changed=true
		for climb: Dictionary in source.get("climbs",[]):
			var id:=str(climb.get("id",""))
			if endpoint_lost(climb,floors,climbs) and not climbs.has(id):
				climbs.append(id)
				changed=true
	return {"supports":supports,"floors":floors,"climbs":climbs}


static func floor_lost(id: String,floors: Array[String],climbs: Array[String]) -> bool:
	for floor in floors:
		if FloorSupportRemoval.removed(id,floor):
			return true
	for climb in climbs:
		if id.begins_with("climb:"+climb+":"):
			return true
	return false


static func endpoint_lost(edge: Dictionary,floors: Array[String],climbs: Array[String]) -> bool:
	return floor_lost(str(edge["from"][0]),floors,climbs) or floor_lost(str(edge["to"][0]),floors,climbs)


static func apply(c: GameController,p: TerrainPiece) -> void:
	var board:=c.state.board
	var before:=board.floor_geometry()
	var source:=board.floor_layout
	var plan:=affected(source,p.dynamic_surface)
	var supports: Array[String]=plan["supports"]
	var floors: Array[String]=plan["floors"]
	var climbs: Array[String]=plan["climbs"]
	var lost: Array[String]=[]
	for surface in before.surfaces:
		if floor_lost(surface.id,floors,climbs):
			lost.append(surface.id)
	var volumes: Array=[]
	for v: Dictionary in source.get("convex_solids",[]):
		if not supports.has(str(v.get("crumble_id",""))) and not supports.has(str(v.get("requires_support",""))):
			volumes.append(v)
	source["convex_solids"]=volumes
	source["surfaces"]=source.get("surfaces",[]).filter(func(s: Dictionary) -> bool: return not floors.has(str(s["id"])))
	for field in ["links","climbs"]:
		source[field]=source.get(field,[]).filter(func(e: Dictionary) -> bool: return not endpoint_lost(e,floors,climbs))
	source["bridges"]=source.get("bridges",[]).filter(func(b: Dictionary) -> bool: return not floors.has(str(b["surface"]["id"])))
	source["walls"]=source.get("walls",[]).filter(func(w: Dictionary) -> bool: return not floors.has(str(w["id"])))
	# Remove effects and targets on vanished surfaces before the normal fall
	# resolver; avoid recursively using a newly rebuilt layout as the old one.
	for piece in board.pieces.duplicate():
		if supports.has(piece.dynamic_surface) or floors.has(piece.dynamic_surface) or floor_lost(piece.surface_id,floors,climbs):
			WizardEye.remove_attached(board,piece)
			board.pieces.erase(piece)
	board.invalidate_terrain()
	c.emit("terrain_changed",{"spell":"crumble","created":false,"at":p.rect.get_center(),"height":p.base_height,"radius":2.0,"collapse":true})
	for id in lost:
		FloorSupportRemoval.resolve(c,before,id)
	FloorSupportRemoval.reconcile(c,before)
