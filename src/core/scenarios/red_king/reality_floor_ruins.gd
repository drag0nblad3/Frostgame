class_name RealityFloorRuins
extends RefCounted
## Translate freestanding authored terrain with collision and riders.
## Permanent connected architecture remains in place.

static func _row(s: GameState,p: TerrainPiece) -> Dictionary:
	for row: Dictionary in s.board.floor_layout.get("walls",[]):
		if row["id"]==p.dynamic_surface and row.get("architectural",false):
			return row
	return {}


static func _rider(surface: String,p: TerrainPiece) -> bool:
	return not p.dynamic_surface.is_empty() and (surface==p.dynamic_surface or surface.begins_with("climb:"+p.dynamic_surface+":"))


static func valid(s: GameState,p: TerrainPiece,offset: Vector2) -> bool:
	var row:=_row(s,p)
	if p.kind.blocks_move and row.is_empty():
		return false
	var target:=Rect2(p.rect.position+offset,p.rect.size)
	var layout:=s.board.floor_geometry()
	var index:=layout.index_of(p.surface_id)
	if index<0:
		return false
	var deck:=layout.surfaces[index]
	if not is_equal_approx(deck.level,deck.end_level) or not deck.contains(target.position) or not deck.contains(target.end):
		return false
	for key in ["links","climbs"]:
		for link: Dictionary in s.board.floor_layout.get(key,[]):
			if str(link["from"][0])==p.dynamic_surface or str(link["to"][0])==p.dynamic_surface:
				return false
	for bridge: Dictionary in s.board.floor_layout.get("bridges",[]):
		for link: Dictionary in bridge.get("links",[]):
			if str(link["from"][0])==p.dynamic_surface or str(link["to"][0])==p.dynamic_surface:
				return false
	for other in s.board.pieces:
		if other!=p and other.eye_host!=p and (other.surface_id==p.surface_id or _rider(other.surface_id,p)) and (target.intersects(other.rect) or _rider(other.surface_id,p)):
			return false
	var box:=AABB(Vector3(target.position.x,p.base_height+0.002,target.position.y),Vector3(target.size.x,maxf(0.01,p.kind.height-0.002),target.size.y))
	var original:=FloorWall.solid_for(row) if not row.is_empty() else AABB()
	for solid in layout.solids:
		if solid!=original and solid.intersects(box):
			return false
	for f in s.figures:
		if not f.in_play():
			continue
		if _rider(f.surface_id,p):
			var at:=f.pos+offset
			var body:=AABB(Vector3(at.x-Figure.BASE_RADIUS,f.elevation+0.002,at.y-Figure.BASE_RADIUS),Vector3(Figure.BASE_RADIUS*2,1.6,Figure.BASE_RADIUS*2))
			for solid in layout.solids:
				if solid!=original and solid.intersects(body):
					return false
			for other in s.figures:
				if other!=f and other.in_play() and not _rider(other.surface_id,p) and absf(other.elevation-f.elevation)<0.5 and other.pos.distance_to(at)<Contact.OVERLAP:
					return false
		elif RealityFloorTerrain.touches_height(p,f.elevation,1.6) and target.grow(Figure.BASE_RADIUS).has_point(f.pos):
			return false
	for token in s.treasures:
		if token.on_ground() and not _rider(token.surface_id,p) and RealityFloorTerrain.touches_height(p,TreasureRules.token_height(s,token),0.5) and target.grow(TreasureRules.TOKEN_RADIUS).has_point(token.pos):
			return false
	return true


static func shift(c: GameController,p: TerrainPiece,offset: Vector2) -> void:
	var s:=c.state
	if not valid(s,p,offset):
		return
	var row:=_row(s,p)
	p.rect.position+=offset
	if not row.is_empty():
		row["rect"]=[p.rect.position.x,p.rect.position.y,p.rect.size.x,p.rect.size.y]
	for attached in s.board.pieces:
		if attached.eye_host==p:
			attached.rect.position+=offset
	s.board.invalidate_terrain()
	for f in s.figures:
		if f.in_play() and _rider(f.surface_id,p):
			var from:=Vector3(f.pos.x,f.elevation,f.pos.y)
			f.pos+=offset
			f.disengaged.clear()
			for other in s.figures:
				other.disengaged.erase(f.id)
			c.emit("layered_move",{"id":f.id,"path":PackedVector3Array([from,Vector3(f.pos.x,f.elevation,f.pos.y)]),"surfaces":[f.surface_id,f.surface_id],"cost":0.0,"teleport":true})
	for token in s.treasures:
		if token.on_ground() and _rider(token.surface_id,p):
			c._loot.relocate_ground(token,token.pos+offset,token.surface_id)
	c.emit("terrain_changed",{"spell":"reality_ruins","created":true})
