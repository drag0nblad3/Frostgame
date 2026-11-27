class_name FloorWall
extends RefCounted
## A conjured wall is a real solid volume and a walkable top. The standard
## floor climbing helper supplies ascent/descent and hanging endpoints.
## TerrainPiece owns the effect's rules, expiry and art; this is geometry.

static func id_for(f: Figure,turn: int,at: Vector2,support: String) -> String:
	return "wall:%d:%d:%d:%d:%s"%[f.id,turn,roundi(at.x*2),roundi(at.y*2),support]


static func solid_for(entry: Dictionary) -> AABB:
	var r: Array=entry["rect"]
	return AABB(Vector3(r[0],entry["height"],r[1]),Vector3(r[2],float(entry.get("thickness",3.0)),r[3]))


static func legal(s: GameState,layout: FloorLayout,f: Figure,n: Vector3i,rect: Rect2) -> bool:
	var surface:=layout.surfaces[n.z]
	if surface.id.begins_with("bridge:") or surface.id.begins_with("wall:"):
		return false
	var h:=layout.height(n)
	var volume:=AABB(Vector3(rect.position.x,h+0.002,rect.position.y),Vector3(rect.size.x,2.998,rect.size.y))
	for solid in layout.solids:
		if solid.intersects(volume):
			return false
	for deck in layout.surfaces:
		if deck.id==surface.id or not deck.rect.intersects(rect):
			continue
		# Do not overwrite another route or its supporting deck.
		if maxf(deck.level,deck.end_level)>h+0.001 and minf(deck.level,deck.end_level)<=h+3.001:
			return false
	for other in s.figures:
		if not other.in_play():
			continue
		var body:=AABB(Vector3(other.pos.x-Figure.BASE_RADIUS,other.elevation+0.002,other.pos.y-Figure.BASE_RADIUS),Vector3(Figure.BASE_RADIUS*2,1.6,Figure.BASE_RADIUS*2))
		if volume.intersects(body):
			return false
	for token in s.treasures:
		if token.on_ground() and token.surface_id==surface.id and rect.grow(TreasureRules.TOKEN_RADIUS).has_point(token.pos):
			return false
	# Avoid engulfing temporary ground effects or anchoring on a temporary
	# surface. Existing spells retain their own lifecycle.
	for p in s.board.pieces:
		if p.surface_id==surface.id and p.rect.intersects(rect):
			return false
	for at in [rect.position,rect.end,rect.position+Vector2(rect.size.x,0),rect.position+Vector2(0,rect.size.y)]:
		if ScenarioNull.field_at(s.board,at,0.0):
			return false
	return true


static func add_volume(layout: FloorLayout,entry: Dictionary) -> void:
	var id:=str(entry["id"])
	if layout.index_of(id)>=0 or layout.index_of(str(entry["support"]))<0:
		layout.errors.append("Invalid conjured wall "+id)
		return
	var solid:=solid_for(entry)
	layout.solids.append(solid)
	layout.magic_solids.append(solid)
	if not bool(entry.get("walkable",true)):
		return
	var surface:=FloorSurface.from_dict({"id":id,"rect":entry["rect"],"level":solid.end.y})
	layout.surfaces.append(surface)


static func add_climbs(layout: FloorLayout,entry: Dictionary) -> void:
	var id:=str(entry["id"])
	var index:=layout.index_of(id)
	if index<0:
		return
	var surface:=layout.surfaces[index]
	var rect:=surface.rect
	var rotated:=rect.size.y>rect.size.x
	var along:=Vector2.DOWN if rotated else Vector2.RIGHT
	var across:=Vector2.RIGHT if rotated else Vector2.DOWN
	var h:=float(entry["height"])
	var rise:=surface.level-h
	var length:=rect.size.y if rotated else rect.size.x
	var width:=rect.size.x if rotated else rect.size.y
	for i in range(1,int(length*2)):
		var at:=rect.get_center()+along*(float(i)*0.5-length*0.5)
		for side: int in [-1,1]:
			var outside:=at+across*(width*0.5+Figure.BASE_RADIUS)*side
			var a:=layout.node(str(entry["support"]),outside)
			var b:=layout.node(id,at)
			if not layout.standable(a) or not layout.standable(b) or not is_equal_approx(layout.height(a),h):
				continue
			var clear:=true
			var steps:=maxi(1,ceili(rise*10.0))
			for step in range(steps+1):
				if not layout.clearance(Vector3(outside.x,h+rise*float(step)/steps,outside.y),Figure.BASE_RADIUS,1.6):
					clear=false
					break
			if not clear:
				continue
			for step in range(11):
				if not layout.clearance(Vector3(outside.x,h+rise,outside.y).lerp(layout.world(b),step/10.0),Figure.BASE_RADIUS,1.6):
					clear=false
					break
			if clear:
				FloorClimb.add(layout,{"id":id+":"+str(i)+":"+str(side),"from":[entry["support"],outside.x,outside.y],"to":[id,at.x,at.y]})
