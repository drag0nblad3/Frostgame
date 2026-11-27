class_name DeploymentRules
extends RefCounted
## Initial placement only. Default edge and named exceptions use one validator.
const STANDARD := ["treasure_skirmish","sunken_streets","mausoleum","living_museum","dreams_well","worm_hunts","haunted_houses","the_keep","genie_in_the_bottle","silent_tower","complex_temple","red_king_squatter","red_king_demons_and_mad_man","red_king_sinkhole","red_king_hill","red_king_tethers"]
const EDGE_NAMES := ["North","East","South","West"]


static func mode(id: String) -> String:
	if id in STANDARD:
		return "edge"
	match id:
		"underground_library": return "door"
		"red_king_back_into_fire","red_king_herded": return "corner6"
		"red_king_bridge": return "corner4"
		"red_king_veil": return "veil"
		"red_king_ringworld": return "ring"
		"red_king_investigations": return "edge"
	return "fixed"


static func choices(id: String) -> Array[int]:
	# Preserve the authored well symmetry and the camp's two entrances.
	if id=="dreams_well":
		return [1,3]
	if id=="red_king_investigations":
		return [0,2]
	match mode(id):
		"edge","door": return [0,1,2,3]
		"corner6","corner4": return [0,1]
		"veil","ring": return [0]
	return []


static func rival(id: String,edge: int) -> int:
	if mode(id)=="ring":
		return 0
	return 1-edge if mode(id).begins_with("corner") else posmod(edge+2,4)


static func edge_point(size: Vector2,edge: int) -> Vector2:
	match edge:
		0: return Vector2(size.x*0.5,0)
		1: return Vector2(size.x,size.y*0.5)
		2: return Vector2(size.x*0.5,size.y)
	return Vector2(0,size.y*0.5)


static func zone(id: String,size: Vector2,edge: int,at: Vector2) -> bool:
	if not Rect2(Vector2.ZERO,size).has_point(at):
		return false
	var m:=mode(id)
	if m=="ring":
		return at.distance_to(size*0.5)<=11.001
	if m=="door":
		return at.distance_to(edge_point(size,edge))<=6.001
	if m.begins_with("corner"):
		var corner:=Vector2.ZERO if edge==0 else Vector2(size.x,0)
		return at.distance_to(corner)<=(4.001 if m=="corner4" else 6.001)
	if m=="veil":
		return at.y<=1.5 # Digital interpretation of adjacent to the short edge.
	if m!="edge":
		return false
	var along:=at.x if edge%2==0 else at.y
	var length:=size.x if edge%2==0 else size.y
	var depth:=at.y if edge==0 else (size.x-at.x if edge==1 else (size.y-at.y if edge==2 else at.x))
	return depth<=3.001 and along>=6.0 and along<=length-6.0


## Ignore initial placeholder warbands; validate against the draft instead.
static func support(s: GameState,at: Vector2) -> Dictionary:
	if not s.board.contains(at,Figure.BASE_RADIUS) or s.board.over_void(at,Figure.BASE_RADIUS):
		return {}
	if s.board.floor_layout.is_empty():
		if not s.board.can_stand(at,Figure.BASE_RADIUS):
			return {}
		return {"at":at,"height":s.board.height_at(at),"surface":""}
	var layout:=s.board.floor_geometry()
	var node: Variant=BattlePlacement.support(s,at,"street",Figure.BASE_RADIUS,1.6,false)
	if node==null:
		return {}
	return {"at":at,"height":layout.height(node),"surface":layout.surface_id(node)}


static func legal(s: GameState,at: Vector2,draft: Dictionary,id: int) -> Dictionary:
	var p:=support(s,at)
	if p.is_empty():
		return {}
	for f in s.figures:
		if f.id==id or f.side>=0 or not f.in_play() or (s.board.ringworld and f.ring_side!=0):
			continue
		if absf(f.elevation-float(p["height"]))<0.5 and f.pos.distance_to(at)<Contact.OVERLAP:
			return {}
	for key: int in draft:
		if key==id:
			continue
		var other: Dictionary=draft[key]
		var other_at: Vector2=other["at"]
		if absf(float(other["height"])-float(p["height"]))<0.5 and other_at.distance_to(at)<Contact.OVERLAP:
			return {}
	for token in s.treasures:
		if not token.on_ground() or (s.board.ringworld and token.ring_side!=0):
			continue
		var h:=TreasureRules.token_height(s,token)
		if not is_nan(h) and absf(h-float(p["height"]))<0.5 and token.pos.distance_to(at)<Figure.BASE_RADIUS+TreasureRules.TOKEN_RADIUS:
			return {}
	return p


static func points(s: GameState,id: String,edge: int) -> Array[Vector2]:
	var result: Array[Vector2]=[]
	for x in range(1,int(s.board.size.x*2)):
		for y in range(1,int(s.board.size.y*2)):
			var at:=Vector2(x,y)*0.5
			if zone(id,s.board.size,edge,at) and not support(s,at).is_empty():
				result.append(at)
	return result
