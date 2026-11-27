class_name RealityFloorTerrain
extends RefCounted
## Dynamic nonwalkable obstacles use actual support and collision volumes.

static func touches_height(p: TerrainPiece,h: float,body: float) -> bool:
	return not is_nan(h) and h<p.base_height+p.kind.height and h+body>p.base_height


static func _entry(p: TerrainPiece) -> Dictionary:
	return {"id":p.dynamic_surface,"support":p.surface_id,"height":p.base_height,"thickness":p.kind.height,"walkable":false,"rect":[p.rect.position.x,p.rect.position.y,p.rect.size.x,p.rect.size.y]}


static func place_disc(c: GameController,p: TerrainPiece) -> bool:
	var s:=c.state
	var layout:=s.board.floor_geometry()
	var candidates: Array[FloorSurface]=[]
	for deck in layout.surfaces:
		if deck.id.begins_with("climb:") or deck.id.begins_with("bridge:") or deck.id.begins_with("wall:") or not deck.contains(p.rect.get_center(),p.rect.size.x*0.5):
			continue
		if is_equal_approx(deck.level,deck.end_level):
			candidates.append(deck)
	candidates.sort_custom(func(a: FloorSurface,b: FloorSurface) -> bool: return a.level<b.level)
	for deck in candidates:
		var box:=AABB(Vector3(p.rect.position.x,deck.level+0.002,p.rect.position.y),Vector3(p.rect.size.x,p.kind.height-0.002,p.rect.size.y))
		var blocked:=blocks_connection(layout,box,AABB())
		for solid in layout.solids:
			if solid.intersects(box):
				blocked=true
				break
		if blocked:
			continue
		p.surface_id=deck.id
		p.base_height=deck.level
		p.dynamic_surface=p.kind.id
		var rows: Array=s.board.floor_layout.get("walls",[])
		rows.append(_entry(p))
		s.board.floor_layout["walls"]=rows
		return true
	return false


static func remove_disc(s: GameState,p: TerrainPiece) -> void:
	if s.board.floor_layout.is_empty():
		return
	var rows: Array=s.board.floor_layout.get("walls",[])
	for row in rows.duplicate():
		if row["id"]==p.dynamic_surface:
			rows.erase(row)
	s.board.floor_layout["walls"]=rows


static func move_disc(c: GameController,p: TerrainPiece,at: Vector2) -> bool:
	var s:=c.state
	var old:=p.rect
	remove_disc(s,p)
	p.rect.position=at-p.rect.size*0.5
	if place_disc(c,p):
		return true
	p.rect=old
	var rows: Array=s.board.floor_layout.get("walls",[])
	rows.append(_entry(p))
	s.board.floor_layout["walls"]=rows
	return false


static func relocate_touching(c: GameController,p: TerrainPiece) -> void:
	var s:=c.state
	var center:=p.rect.get_center()
	for f in s.figures.duplicate():
		if not f.in_play() or not touches_height(p,f.elevation,1.6) or not p.rect.grow(Figure.BASE_RADIUS).has_point(f.pos):
			continue
		var direction: Vector2=f.pos-center
		if direction.is_zero_approx():
			direction=RealityCracks.direction(c)
		var desired:=center+direction.normalized()*(p.rect.size.x*0.5+Figure.BASE_RADIUS+0.1)
		var n: Variant=ForcedRelocation.destination_floor(s,f,desired)
		if n!=null:
			ForcedRelocation.apply_floor(c,f,n)
	for t in s.treasures:
		if not t.on_ground() or not touches_height(p,TreasureRules.token_height(s,t),0.5) or not p.rect.grow(TreasureRules.TOKEN_RADIUS).has_point(t.pos):
			continue
		var best: Variant=null
		var distance:=INF
		var layout:=s.board.floor_geometry()
		var index:=layout.index_of(t.surface_id)
		if index<0:
			continue
		for n in BattlePlacement.nodes(s.board,t.pos,4.0,index):
			if not layout.standable(n,TreasureRules.TOKEN_RADIUS,0.5):
				continue
			var d:=layout.point(n).distance_squared_to(t.pos)
			if d<distance:
				distance=d
				best=n
		if best!=null:
			c._loot.relocate_ground(t,layout.point(best),t.surface_id)


## Keep existing walk/stair/climb links usable when dynamic obstacles
## materialize. Links that belong to the moved solid are regenerated.
static func blocks_connection(layout: FloorLayout,volume: AABB,original: AABB) -> bool:
	var padding:=Vector3(Figure.BASE_RADIUS,1.6,Figure.BASE_RADIUS)
	var expanded:=AABB(volume.position-padding,volume.size+Vector3(padding.x*2,padding.y,padding.z*2))
	for n: Vector3i in layout.links:
		var start:=layout.world(n)
		for edge: Dictionary in layout.links[n]:
			var end:=layout.world(edge["to"])
			if original.has_volume() and (original.grow(Figure.BASE_RADIUS+0.001).has_point(start) or original.grow(Figure.BASE_RADIUS+0.001).has_point(end)):
				continue
			if LayeredSight.intersects(start+Vector3.UP*0.01,end+Vector3.UP*0.01,expanded):
				return true
	return false
